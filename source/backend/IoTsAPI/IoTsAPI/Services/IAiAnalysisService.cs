using IoTsAPI.Models;

namespace IoTsAPI.Services;

public record AnomalyContext(
    string DeviceName,
    string DeviceType,
    string Location,
    double BaselineAvg,
    double BaselineStdDev,
    double TodayValue,
    double ZScore,
    List<(string Date, double Wh)> RecentHistory
);

public record TrendContext(
    string DeviceName,
    string DeviceType,
    string Location,
    double SlopePerDay,  // Wh tăng thêm mỗi ngày
    double CurrentAvg,
    List<(string Date, double Wh)> RecentHistory
);

public record ScheduleContext(
    string DeviceName,
    string DeviceType,
    string Location,
    List<(string DayOfWeek, string Time, bool IsOn)> Schedules,
    List<(string Date, double Wh)> UsageByDay,
    double AvgDailyUsage
);

public interface IAiAnalysisService
{
    Task<string> AnalyzeAnomalyAsync(AnomalyContext ctx, CancellationToken ct = default);
    Task<string> AnalyzeTrendAsync(TrendContext ctx, CancellationToken ct = default);
    Task<string> SuggestScheduleOptimizationAsync(ScheduleContext ctx, CancellationToken ct = default);
}
