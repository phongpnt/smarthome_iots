using IoTsAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace IoTsAPI.Services;

public class AiWarningBackgroundService : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly IAiAnalysisService _ai;
    private readonly ILogger<AiWarningBackgroundService> _logger;
    private readonly TimeSpan _interval;

    private readonly double _anomalyZThreshold;  // mặc định 2.0
    private readonly double _trendSlopeThreshold;  // Wh/ngày, mặc định 10
    private readonly int _baselineDays;  // số ngày tính baseline, mặc định 30
    private readonly int _minLogsRequired;  // cần ít nhất n log để phân tích

    private const string PrefixAnomaly    = "[AI] Tiêu thụ bất thường";
    private const string PrefixTrend      = "[AI] Xu hướng tăng điện";
    private const string PrefixSchedule   = "[AI] Gợi ý lịch tối ưu";
    private const string PrefixIsoForest  = "[Isolation Forest] Bất thường hành vi";
    private const string PrefixProphet    = "[Prophet] Dự báo tăng tiêu thụ";

    private readonly IsolationForestService _isoForest = new();
    private readonly double _isoScoreThreshold;
    private readonly int    _isoBaselineDays;

    private readonly ProphetService _prophet = new();
    private readonly int    _prophetBaselineDays;
    private readonly double _prophetSlopeThreshold;
    private readonly double _prophetChangeThreshold;

    public AiWarningBackgroundService(
        IServiceScopeFactory scopeFactory,
        IAiAnalysisService ai,
        ILogger<AiWarningBackgroundService> logger,
        IConfiguration config)
    {
        _scopeFactory = scopeFactory;
        _ai = ai;
        _logger = logger;

        var section = config.GetSection("AiWarning");
        _interval             = TimeSpan.FromMinutes(section.GetValue("IntervalMinutes", 60));
        _anomalyZThreshold    = section.GetValue("AnomalyZThreshold", 2.0);
        _trendSlopeThreshold  = section.GetValue("TrendSlopeThresholdWh", 10.0);
        _baselineDays         = section.GetValue("BaselineDays", 30);
        _minLogsRequired      = section.GetValue("MinLogsRequired", 5);
        _isoScoreThreshold    = section.GetValue("IsoForestScoreThreshold", 0.68);
        _isoBaselineDays      = section.GetValue("IsoForestBaselineDays", 120);

        _prophetBaselineDays    = section.GetValue("ProphetBaselineDays", 60);
        _prophetSlopeThreshold  = section.GetValue("ProphetSlopeThresholdWh", 20.0);
        _prophetChangeThreshold = section.GetValue("ProphetChangeThresholdPercent", 25.0);
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("AiWarningBackgroundService started. Interval: {Interval}", _interval);

        await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await RunAnalysisAsync(stoppingToken);
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                _logger.LogError(ex, "Error in AI warning analysis");
            }

            await Task.Delay(_interval, stoppingToken);
        }
    }

    private async Task RunAnalysisAsync(CancellationToken ct)
    {
        using var scope = _scopeFactory.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<IoTsContext>();

        var cutoff = DateTime.Now.AddDays(-_baselineDays);
        var today = DateTime.Now.Date;

        var devices = await db.Devices.ToListAsync(ct);

        var allLogs = await db.UsagePowerLogs
            .Where(l => l.CalculateDate >= cutoff)
            .ToListAsync(ct);

        var allSchedules = await db.Schedules
            .Where(s => s.Active)
            .ToListAsync(ct);

        int warningsInserted = 0;

        foreach (var device in devices)
        {
            var deviceLogs = allLogs
                .Where(l => l.DeviceId == device.DeviceId)
                .OrderBy(l => l.CalculateDate)
                .ToList();

            if (deviceLogs.Count < _minLogsRequired) continue;

            var byDay = deviceLogs
                .GroupBy(l => l.CalculateDate.Date)
                .Select(g => (Date: g.Key, Wh: g.Sum(x => x.PowerUsageWat)))
                .OrderBy(x => x.Date)
                .ToList();

            var history = byDay.Select(x => (x.Date.ToString("dd/MM"), x.Wh)).ToList();

            var todayLog = byDay.FirstOrDefault(x => x.Date == today);
            if (todayLog.Date == today)
            {
                var baseline = byDay
                    .Where(x => x.Date < today)
                    .Select(x => x.Wh)
                    .ToList();

                if (baseline.Count >= 3)
                {
                    var z = PowerAnalyzer.ZScore(baseline, todayLog.Wh);
                    if (z >= _anomalyZThreshold)
                    {
                        var exists = await WarningExistsAsync(db, device.DeviceId, PrefixAnomaly, today, ct);
                        if (!exists)
                        {
                            var ctx = new AnomalyContext(
                                device.DeviceName, device.Type, device.Location ?? "",
                                baseline.Average(), PowerAnalyzer.StdDev(baseline),
                                todayLog.Wh, z,
                                history.TakeLast(7).ToList()
                            );
                            var content = await SafeCallAiAsync(() => _ai.AnalyzeAnomalyAsync(ctx, ct));
                            await InsertWarningAsync(db, device, PrefixAnomaly, content, ct);
                            warningsInserted++;
                        }
                    }
                }
            }

            var last7 = byDay.TakeLast(7).ToList();
            if (last7.Count >= 5)
            {
                var values = last7.Select(x => x.Wh).ToList();
                var slope = PowerAnalyzer.LinearRegressionSlope(values);

                if (slope >= _trendSlopeThreshold)
                {
                    var weekStart = today.AddDays(-(int)today.DayOfWeek);
                    var trendExists = await db.Warnings.AnyAsync(w =>
                        w.DeviceId == device.DeviceId &&
                        w.WarningTitle.StartsWith(PrefixTrend) &&
                        w.CreatedDate >= weekStart, ct);

                    if (!trendExists)
                    {
                        var ctx = new TrendContext(
                            device.DeviceName, device.Type, device.Location ?? "",
                            slope,
                            values.Average(),
                            last7.Select(x => (x.Date.ToString("dd/MM"), x.Wh)).ToList()
                        );
                        var content = await SafeCallAiAsync(() => _ai.AnalyzeTrendAsync(ctx, ct));
                        await InsertWarningAsync(db, device, PrefixTrend, content, ct);
                        warningsInserted++;
                    }
                }
            }

            var deviceSchedules = allSchedules
                .Where(s => s.DeviceId == device.DeviceId)
                .ToList();

            if (deviceSchedules.Count > 0 && byDay.Count >= 7)
            {
                var monthStart = new DateTime(today.Year, today.Month, 1);
                var scheduleExists = await db.Warnings.AnyAsync(w =>
                    w.DeviceId == device.DeviceId &&
                    w.WarningTitle.StartsWith(PrefixSchedule) &&
                    w.CreatedDate >= monthStart, ct);

                if (!scheduleExists)
                {
                    var avgUsage = byDay.TakeLast(30).Average(x => x.Wh);

                    var hasOnSchedule = deviceSchedules.Any(s => s.PowerStatus);
                    var usageIsLow = avgUsage < 5.0;  // < 5Wh/ngày khi có lịch bật → nghi ngờ

                    var usageStdDev = PowerAnalyzer.StdDev(byDay.TakeLast(14).Select(x => x.Wh).ToList());
                    var isHighVariance = usageStdDev > avgUsage * 0.5;  // CV > 50%

                    if ((hasOnSchedule && usageIsLow) || isHighVariance)
                    {
                        var ctx = new ScheduleContext(
                            device.DeviceName, device.Type, device.Location ?? "",
                            deviceSchedules.Select(s => (s.DayOfWeek, s.Time, s.PowerStatus)).ToList(),
                            byDay.TakeLast(14).Select(x => (x.Date.ToString("dd/MM"), x.Wh)).ToList(),
                            avgUsage
                        );
                        var content = await SafeCallAiAsync(() => _ai.SuggestScheduleOptimizationAsync(ctx, ct));
                        await InsertWarningAsync(db, device, PrefixSchedule, content, ct);
                        warningsInserted++;
                    }
                }
            }
        }

        warningsInserted += await RunIsolationForestAsync(db, devices, today, ct);

        warningsInserted += await RunProphetAsync(db, devices, today, ct);

        if (warningsInserted > 0)
            _logger.LogInformation("AI Warning analysis completed: {Count} warnings inserted", warningsInserted);
    }

    private async Task<int> RunIsolationForestAsync(
        IoTsContext db,
        List<Device> devices,
        DateTime today,
        CancellationToken ct)
    {
        var isoCutoff = today.AddDays(-_isoBaselineDays);
        var isoLogs   = await db.UsagePowerLogs
            .Where(l => l.CalculateDate >= isoCutoff)
            .ToListAsync(ct);

        int inserted = 0;

        foreach (var device in devices)
        {
            var deviceLogs = isoLogs
                .Where(l => l.DeviceId == device.DeviceId)
                .ToList();

            if (deviceLogs.Count < 15) continue;  // cần đủ data để train

            var trainingLogs = deviceLogs
                .Where(l => l.CalculateDate.Date < today)
                .ToList();

            var todayLogs = deviceLogs
                .Where(l => l.CalculateDate.Date == today)
                .ToList();

            if (trainingLogs.Count < 10 || todayLogs.Count == 0) continue;

            var anomalies = _isoForest.Detect(trainingLogs, todayLogs, _isoScoreThreshold);
            if (anomalies.Count == 0) continue;

            var alreadyExists = await db.Warnings.AnyAsync(w =>
                w.DeviceId == device.DeviceId &&
                w.WarningSource == "isolation_forest" &&
                w.CreatedDate >= today &&
                w.CreatedDate < today.AddDays(1), ct);

            if (alreadyExists) continue;

            var top = anomalies.OrderByDescending(a => a.AnomalyScore).First();

            var title   = $"{PrefixIsoForest} thiết bị";
            var content = $"Mô hình ML phát hiện pattern tiêu thụ lúc " +
                          $"{top.Timestamp:HH:mm} ({top.PowerWh:F1} W) không khớp với " +
                          $"{trainingLogs.Count} mẫu lịch sử. " +
                          $"Điểm bất thường: {top.AnomalyScore:F2}/1.00.";

            var warning = new Warning
            {
                WarningId      = Guid.NewGuid().ToString("N")[..20],
                CreatedDate    = DateTime.Now,
                WarningTitle   = title,
                WarningContent = content.Length > 450 ? content[..447] + "..." : content,
                NewIcon        = true,
                DeviceId       = device.DeviceId,
                DeviceName     = device.DeviceName,
                Location       = device.Location ?? "",
                DeviceType     = device.Type,
                WarningSource  = "isolation_forest",
                AnomalyScore   = top.AnomalyScore,
            };

            db.Warnings.Add(warning);
            await db.SaveChangesAsync(ct);

            _logger.LogInformation(
                "[IsoForest] Device={Name} score={Score:F3} time={Time}",
                device.DeviceName, top.AnomalyScore, top.Timestamp);

            inserted++;
        }

        return inserted;
    }

    private async Task<int> RunProphetAsync(
        IoTsContext db,
        List<Device> devices,
        DateTime today,
        CancellationToken ct)
    {
        var cutoff    = today.AddDays(-_prophetBaselineDays);
        var prophetLogs = await db.UsagePowerLogs
            .Where(l => l.CalculateDate >= cutoff && l.CalculateDate.Date < today)
            .ToListAsync(ct);

        int inserted = 0;

        foreach (var device in devices)
        {
            var daily = prophetLogs
                .Where(l => l.DeviceId == device.DeviceId)
                .GroupBy(l => l.CalculateDate.Date)
                .Select(g => (Date: g.Key, Wh: g.Sum(x => x.PowerUsageWat)))
                .OrderBy(x => x.Date)
                .ToList();

            if (daily.Count < 14) continue;  // Prophet needs ≥ 2 weeks

            var forecast = _prophet.Forecast(daily, horizonDays: 7);
            if (forecast is null) continue;

            bool isTrendAlert    = forecast.TrendSlopeWhPerDay >= _prophetSlopeThreshold;
            bool isForecastAlert = forecast.ChangePercent       >= _prophetChangeThreshold;
            if (!isTrendAlert && !isForecastAlert) continue;

            var weekStart = today.AddDays(-(int)today.DayOfWeek);
            var exists = await db.Warnings.AnyAsync(w =>
                w.DeviceId == device.DeviceId &&
                w.WarningSource == "prophet" &&
                w.CreatedDate >= weekStart, ct);

            if (exists) continue;

            string reason = isTrendAlert
                ? $"xu hướng tăng {forecast.TrendSlopeWhPerDay:F1} Wh/ngày"
                : $"dự báo tăng {forecast.ChangePercent:F0}% so với tuần qua";

            var nextWeekPeak = forecast.Points.Max(p => p.Predicted);

            var content = $"Prophet phát hiện {reason}. " +
                          $"Dự báo 7 ngày tới TB {forecast.ForecastAvgWh:F0} Wh/ngày " +
                          $"(peak {nextWeekPeak:F0} Wh), " +
                          $"hiện tại {forecast.RecentAvgWh:F0} Wh/ngày.";

            double slopeScore  = Math.Min(1.0, forecast.TrendSlopeWhPerDay / (_prophetSlopeThreshold * 2));
            double changeScore = Math.Min(1.0, Math.Abs(forecast.ChangePercent) / 100.0);
            double score       = Math.Max(slopeScore, changeScore);

            var warning = new Warning
            {
                WarningId      = Guid.NewGuid().ToString("N")[..20],
                CreatedDate    = DateTime.Now,
                WarningTitle   = PrefixProphet,
                WarningContent = content.Length > 450 ? content[..447] + "..." : content,
                NewIcon        = true,
                DeviceId       = device.DeviceId,
                DeviceName     = device.DeviceName,
                Location       = device.Location ?? "",
                DeviceType     = device.Type,
                WarningSource  = "prophet",
                AnomalyScore   = score,
            };

            db.Warnings.Add(warning);
            await db.SaveChangesAsync(ct);

            _logger.LogInformation(
                "[Prophet] Device={Name} slope={Slope:F2} Wh/day change={Change:F1}%",
                device.DeviceName, forecast.TrendSlopeWhPerDay, forecast.ChangePercent);

            inserted++;
        }

        return inserted;
    }

    private static async Task<bool> WarningExistsAsync(
        IoTsContext db, string deviceId, string titlePrefix, DateTime date, CancellationToken ct)
    {
        return await db.Warnings.AnyAsync(w =>
            w.DeviceId == deviceId &&
            w.WarningTitle.StartsWith(titlePrefix) &&
            w.CreatedDate >= date &&
            w.CreatedDate < date.AddDays(1), ct);
    }

    private static async Task InsertWarningAsync(
        IoTsContext db, Device device, string title, string content, CancellationToken ct)
    {
        var truncated = content.Length > 200 ? content[..197] + "..." : content;

        var warning = new Warning
        {
            WarningId      = Guid.NewGuid().ToString("N")[..20],
            CreatedDate    = DateTime.Now,
            WarningTitle   = title,
            WarningContent = truncated,
            NewIcon        = true,
            DeviceId       = device.DeviceId,
            DeviceName     = device.DeviceName,
            Location       = device.Location ?? "",
            DeviceType     = device.Type,
            WarningSource  = "rule",
        };

        db.Warnings.Add(warning);
        await db.SaveChangesAsync(ct);
    }

    private async Task<string> SafeCallAiAsync(Func<Task<string>> aiCall)
    {
        try
        {
            return await aiCall();
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "AI API call failed, using fallback content");
            return "Phát hiện bất thường trong tiêu thụ điện. Vui lòng kiểm tra thiết bị.";
        }
    }
}
