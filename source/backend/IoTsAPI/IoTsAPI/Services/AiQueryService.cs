using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using IoTsAPI.DTOs;
using IoTsAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace IoTsAPI.Services;

public class AiQueryService
{
    private readonly IoTsContext _db;
    private readonly HttpClient _http;
    private readonly ILogger<AiQueryService> _logger;
    private readonly string _model;
    private readonly string _chatUrl;

    private static readonly JsonSerializerOptions _jsonOpts = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DefaultIgnoreCondition =
            System.Text.Json.Serialization.JsonIgnoreCondition.WhenWritingNull
    };

    private static (DateTime Start, DateTime End) MonthRange(int year, int month) =>
        (new DateTime(year, month, 1), new DateTime(year, month, 1).AddMonths(1));

    private const string SystemPrompt =
        "Bạn là trợ lý AI cho hệ thống smart home IoT. Trả lời bằng tiếng Việt, thân thiện, ngắn gọn.\n\n" +
        "QUAN TRỌNG:\n" +
        "- Luôn gọi tool để lấy dữ liệu thực. Không tự suy luận, không tự tính toán, không bịa số liệu.\n" +
        "- Trình bày NGUYÊN VẸN kết quả từ tool: giữ đúng tháng/năm, từng bậc tiền điện, tổng kWh, tổng tiền.\n" +
        "- KHÔNG tóm tắt, KHÔNG tính lại, KHÔNG thêm nhận xét ngoài dữ liệu.\n" +
        "- KHÔNG dùng markdown (không dùng **, ##, -, *). Dùng dòng văn bản thuần.\n\n" +
        "Quy tắc chọn tool:\n" +
        "- 'hôm nay/tuần/tháng dùng bao nhiêu điện' → get_total_energy\n" +
        "- 'tháng trước' hoặc 'tháng X năm Y' → get_total_energy với period=last_month\n" +
        "- 'dự báo tiền điện tháng này' → get_energy_forecast_month\n" +
        "- 'so sánh 3 tháng' → get_monthly_comparison với months=\"3\"\n" +
        "- 'so sánh 6 tháng' → get_monthly_comparison với months=\"6\"\n" +
        "- 'cùng kỳ năm ngoái' → get_yoy_comparison\n" +
        "- 'thiết bị nào tốn điện' → get_top_power_consumers\n" +
        "- 'hôm nay làm gì tiêu thụ điện' → get_top_power_consumers với days=1\n" +
        "- 'thiết bị đang bật/tắt' → get_devices_status\n" +
        "- 'cảnh báo' → get_recent_warnings\n" +
        "- thiết bị cụ thể → get_device_usage_summary\n\n" +
        "Không xuất JSON hoặc XML.";

    public AiQueryService(IoTsContext db, HttpClient http,
        IConfiguration config, ILogger<AiQueryService> logger)
    {
        _db      = db;
        _http    = http;
        _logger  = logger;
        _model   = config["OpenAI:Model"] ?? "gpt-4o-mini";
        _chatUrl = config["OpenAI:ChatUrl"] ?? "https://api.openai.com/v1/chat/completions";

        var apiKey = config["OpenAI:ApiKey"]
            ?? throw new InvalidOperationException("OpenAI:ApiKey not configured");
        _http.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", apiKey);
    }

    public async Task<AiQueryResponse> QueryAsync(
        string question, string userId, CancellationToken ct = default)
    {
        try
        {
            var messages = new List<object>
            {
                new { role = "system", content = SystemPrompt },
                new { role = "user",   content = question }
            };

            for (int round = 0; round < 3; round++)
            {
                var toolChoice = round == 0 ? "required" : "auto";
                var response = await CallOpenAiAsync(messages, ct, toolChoice);

                var choice       = response?["choices"]?[0];
                var finishReason = choice?["finish_reason"]?.GetValue<string>();
                var message      = choice?["message"];

                if (finishReason == "tool_calls")
                {
                    var assistantMsg = JsonSerializer.Deserialize<object>(
                        message!.ToJsonString(), _jsonOpts)!;
                    messages.Add(assistantMsg);

                    var toolCalls = message["tool_calls"]?.AsArray();
                    if (toolCalls == null) break;

                    foreach (var toolCall in toolCalls)
                    {
                        var toolId   = toolCall?["id"]?.GetValue<string>() ?? "";
                        var funcName = toolCall?["function"]?["name"]?.GetValue<string>() ?? "";
                        var argsStr  = toolCall?["function"]?["arguments"]?.GetValue<string>() ?? "{}";

                        var result = await ExecuteFunctionAsync(funcName, argsStr, userId, ct);

                        messages.Add(new
                        {
                            role         = "tool",
                            tool_call_id = toolId,
                            content      = result
                        });
                    }
                }
                else
                {
                    var answer = message?["content"]?.GetValue<string>() ?? "";
                    answer = System.Text.RegularExpressions.Regex.Replace(
                        answer, @"<function[^>]*/?>.*?</function>|<function[^/]*/?>", "",
                        System.Text.RegularExpressions.RegexOptions.Singleline).Trim();
                    return new AiQueryResponse(answer, true);
                }
            }

            return new AiQueryResponse(
                "Tôi chưa xử lý được yêu cầu này. Bạn hãy thử hỏi theo cách khác.", true);
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "AI HTTP error: {Msg}", ex.Message);
            string msg;
            if (ex.Message.Contains("429") || ex.Message.Contains("Rate limit"))
            {
                var isQuota = ex.Message.Contains("quota");
                msg = isQuota
                    ? "Đã hết quota AI. Vui lòng thử lại sau."
                    : "AI đang quá tải (rate limit). Vui lòng đợi 30–60 giây rồi thử lại.";
            }
            else if (ex.Message.Contains("401"))
                msg = "API key AI không hợp lệ hoặc đã hết hạn. Vui lòng kiểm tra cấu hình.";
            else if (ex.Message.Contains("403"))
                msg = "API key AI không có quyền truy cập model này.";
            else if (ex.Message.Contains("503") || ex.Message.Contains("502"))
                msg = "Dịch vụ AI tạm thời không khả dụng. Thử lại sau vài phút.";
            else
                msg = $"Lỗi kết nối AI: {ex.Message[..Math.Min(ex.Message.Length, 120)]}";
            return new AiQueryResponse(msg, true);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "AiQueryService error. Question: {Q}", question);
            return new AiQueryResponse(
                "Tôi chưa thể trả lời lúc này. Vui lòng thử lại sau.", true);
        }
    }

    private async Task<JsonNode?> CallOpenAiAsync(
        List<object> messages, CancellationToken ct, string toolChoice = "auto")
    {
        var body = new
        {
            model       = _model,
            messages,
            tools       = GetToolDefinitions(),
            tool_choice = toolChoice,
            max_tokens  = 1500
        };

        var json = JsonSerializer.Serialize(body, _jsonOpts);

        int[] retryDelaysMs = [8000, 15000];  // chờ 8s → 15s trước mỗi retry
        for (int attempt = 0; attempt < 3; attempt++)
        {
            using var req = new HttpRequestMessage(HttpMethod.Post, _chatUrl)
            {
                Content = new StringContent(json, Encoding.UTF8, "application/json")
            };

            var res = await _http.SendAsync(req, ct);
            var statusCode = (int)res.StatusCode;

            if (statusCode == 429)
            {
                var limitBody = await res.Content.ReadAsStringAsync(ct);
                var isQuota = limitBody.Contains("per day") || limitBody.Contains("per month")
                           || limitBody.Contains("quota") || limitBody.Contains("tomorrow");

                if (isQuota)
                    throw new HttpRequestException("Rate limit quota: đã hết quota AI trong ngày.");

                if (attempt < 2)
                {
                    int delayMs = retryDelaysMs[attempt];
                    if (res.Headers.TryGetValues("Retry-After", out var raValues))
                    {
                        var raStr = raValues.FirstOrDefault();
                        if (double.TryParse(raStr, System.Globalization.NumberStyles.Any,
                            System.Globalization.CultureInfo.InvariantCulture, out var raSec))
                        {
                            delayMs = (int)(raSec * 1000) + 1000;
                            delayMs = Math.Clamp(delayMs, 1000, 35000);
                        }
                    }
                    _logger.LogWarning("Rate limit 429 (attempt {A}) — waiting {D}ms", attempt + 1, delayMs);
                    await Task.Delay(delayMs, ct);
                    continue;
                }

                throw new HttpRequestException("Rate limit (429) sau 3 lần thử.");
            }

            if (!res.IsSuccessStatusCode)
            {
                var errorBody = await res.Content.ReadAsStringAsync(ct);
                _logger.LogError("AI API error {Status}: {Body}", statusCode, errorBody);

                if (statusCode == 400 && attempt < 2)
                {
                    var lower = errorBody.ToLowerInvariant();
                    if (lower.Contains("failed_generation") || lower.Contains("tool call validation")
                        || lower.Contains("invalid_argument") || lower.Contains("recitation"))
                    {
                        _logger.LogWarning("400 generation error (attempt {A}) — retrying: {Err}",
                            attempt + 1, errorBody[..Math.Min(120, errorBody.Length)]);
                        await Task.Delay(1500, ct);
                        continue;
                    }
                }

                throw new HttpRequestException($"API {statusCode}: {errorBody}");
            }

            return JsonNode.Parse(await res.Content.ReadAsStringAsync(ct));
        }

        throw new HttpRequestException("Không gọi được API sau nhiều lần thử.");
    }

    private async Task<string> ExecuteFunctionAsync(
        string funcName, string argsJson, string userId, CancellationToken ct)
    {
        try
        {
            using var doc = JsonDocument.Parse(argsJson);
            var args = doc.RootElement;

            return funcName switch
            {
                "get_top_power_consumers"   => await GetTopPowerConsumers(args, userId, ct),
                "get_device_usage_summary"  => await GetDeviceUsageSummary(args, userId, ct),
                "get_total_energy"          => await GetTotalEnergy(args, userId, ct),
                "get_recent_warnings"       => await GetRecentWarnings(args, userId, ct),
                "get_energy_forecast_month" => await GetEnergyForecastMonth(userId, ct),
                "get_monthly_comparison"    => await GetMonthlyComparison(args, userId, ct),
                "get_yoy_comparison"        => await GetYoyComparison(args, userId, ct),
                "get_devices_status"        => await GetDevicesStatus(userId, ct),
                _ => $"Unknown function: {funcName}"
            };
        }
        catch (Exception ex)
        {
            return $"Error: {ex.Message}";
        }
    }

    private async Task<string> GetTopPowerConsumers(
        JsonElement args, string userId, CancellationToken ct)
    {
        int days  = args.TryGetProperty("days",  out var d) ? d.GetInt32() : 7;
        int limit = args.TryGetProperty("limit", out var l) ? l.GetInt32() : 5;
        var since = DateTime.Now.AddDays(-days);

        var result = await (
            from log in _db.UsagePowerLogs
            join dev in _db.Devices on log.DeviceId equals dev.DeviceId
            where dev.UserId == userId && log.CalculateDate >= since
            group log by new { dev.DeviceId, dev.DeviceName, dev.Location, dev.Type }
            into g
            orderby g.Sum(x => x.PowerUsageWat) descending
            select new
            {
                g.Key.DeviceName, g.Key.Location, g.Key.Type,
                TotalWh = g.Sum(x => x.PowerUsageWat)
            }
        ).Take(limit).ToListAsync(ct);

        if (!result.Any()) return "Không có dữ liệu tiêu thụ điện.";

        return string.Join("\n", result.Select((r, i) =>
            $"{i + 1}. {r.DeviceName} ({r.Type}, {r.Location}): {r.TotalWh:F1} Wh / {days} ngày"));
    }

    private async Task<string> GetDeviceUsageSummary(
        JsonElement args, string userId, CancellationToken ct)
    {
        var period   = args.TryGetProperty("period",      out var p)  ? p.GetString()  : "week";
        var devName  = args.TryGetProperty("device_name", out var n)  ? n.GetString()  : null;
        var deviceId = args.TryGetProperty("device_id",   out var di) ? di.GetString() : null;

        DateTime since = period switch
        {
            "today"  => DateTime.Now.Date,
            "month"  => new DateTime(DateTime.Now.Year, DateTime.Now.Month, 1),
            "last30" => DateTime.Now.AddDays(-30),
            _        => DateTime.Now.AddDays(-7)
        };

        var deviceQuery = _db.Devices.Where(d => d.UserId == userId);
        if (!string.IsNullOrEmpty(deviceId))
            deviceQuery = deviceQuery.Where(d => d.DeviceId == deviceId);
        else if (!string.IsNullOrEmpty(devName))
            deviceQuery = deviceQuery.Where(d =>
                d.DeviceName.Contains(devName) || d.Type.Contains(devName));

        var devices = await deviceQuery.ToListAsync(ct);

        if (!devices.Any() && !string.IsNullOrEmpty(deviceId))
        {
            var fallbackDev = await _db.Devices.FirstOrDefaultAsync(d => d.DeviceId == deviceId, ct);
            if (fallbackDev != null) devices = [fallbackDev];
        }

        if (!devices.Any())
            return $"Không tìm thấy thiết bị '{devName ?? deviceId}'.";

        var deviceIds = devices.Select(d => d.DeviceId).ToList();
        var totalWh = await _db.UsagePowerLogs
            .Where(l => deviceIds.Contains(l.DeviceId) && l.CalculateDate >= since)
            .SumAsync(l => l.PowerUsageWat, ct);

        if (totalWh == 0) return $"Không có dữ liệu cho '{devName}' trong khoảng thời gian này.";

        var label = period switch { "today" => "hôm nay", "month" => "tháng này", "last30" => "30 ngày gần nhất", _ => "tuần này" };
        var dev = devices.First();
        return $"{dev.DeviceName} ({dev.Location}) — {label}: {totalWh:F1} Wh " +
               $"(≈ {totalWh / 1000 * 3500:F0} VNĐ)";
    }

    private async Task<string> GetTotalEnergy(
        JsonElement args, string userId, CancellationToken ct)
    {
        var period = args.TryGetProperty("period", out var p) ? p.GetString() : "today";

        var now            = DateTime.Now;
        var thisMonthStart = new DateTime(now.Year, now.Month, 1);
        var lastMonthStart = thisMonthStart.AddMonths(-1);

        DateTime since;
        DateTime? until = null;
        string label;

        switch (period)
        {
            case "week":
                since = now.AddDays(-7);
                label = "tuần này";
                break;
            case "month":
                since = thisMonthStart;
                label = $"tháng {thisMonthStart.Month}/{thisMonthStart.Year}";
                break;
            case "last_month":
                since = lastMonthStart;
                until = thisMonthStart;
                label = $"tháng {lastMonthStart.Month}/{lastMonthStart.Year}";
                break;
            default:  // today
                since = now.Date;
                label = "hôm nay";
                break;
        }

        var deviceIds = await _db.Devices
            .Where(d => d.UserId == userId).Select(d => d.DeviceId).ToListAsync(ct);

        if (!deviceIds.Any()) return "Không có thiết bị nào.";

        var query = _db.UsagePowerLogs
            .Where(l => deviceIds.Contains(l.DeviceId) && l.CalculateDate >= since);

        if (until.HasValue)
            query = query.Where(l => l.CalculateDate < until.Value);

        var totalWh = await query.SumAsync(l => l.PowerUsageWat, ct);

        if (totalWh == 0) return $"Chưa có dữ liệu điện năng {label}.";

        double kWh = totalWh / 1000;
        var (bill, detail) = CalculateTieredBill(kWh);

        if (period == "last_month")
        {
            return $"Điện năng {label} ({deviceIds.Count} thiết bị):\n" +
                   $"  Tổng: {totalWh:F1} Wh ({kWh:F3} kWh)\n" +
                   $"Chi tiết hóa đơn EVN:\n{detail}";
        }

        return $"Tổng điện năng {label} ({deviceIds.Count} thiết bị): " +
               $"{totalWh:F1} Wh ({kWh:F3} kWh)\n" +
               $"Ước tính tiền điện (thang bậc EVN): {bill:N0} VNĐ (đã VAT)";
    }

    private async Task<string> GetRecentWarnings(
        JsonElement args, string userId, CancellationToken ct)
    {
        int limit = args.TryGetProperty("limit", out var l) ? l.GetInt32() : 5;

        var deviceIds = await _db.Devices
            .Where(d => d.UserId == userId).Select(d => d.DeviceId).ToListAsync(ct);

        var warnings = await _db.Warnings
            .Where(w => deviceIds.Contains(w.DeviceId))
            .OrderByDescending(w => w.CreatedDate)
            .Take(limit).ToListAsync(ct);

        if (!warnings.Any()) return "Không có cảnh báo nào gần đây.";

        return string.Join("\n", warnings.Select(w =>
            $"[{w.CreatedDate:dd/MM HH:mm}] {w.WarningTitle} — {w.DeviceName}: {w.WarningContent}"));
    }

    private async Task<string> GetEnergyForecastMonth(string userId, CancellationToken ct)
    {
        var monthStart   = new DateTime(DateTime.Now.Year, DateTime.Now.Month, 1);
        int daysPassed   = (DateTime.Now.Date - monthStart).Days + 1;
        int daysInMonth  = DateTime.DaysInMonth(DateTime.Now.Year, DateTime.Now.Month);

        var deviceIds = await _db.Devices
            .Where(d => d.UserId == userId).Select(d => d.DeviceId).ToListAsync(ct);

        var usedWh = await _db.UsagePowerLogs
            .Where(l => deviceIds.Contains(l.DeviceId) && l.CalculateDate >= monthStart)
            .SumAsync(l => l.PowerUsageWat, ct);

        if (usedWh == 0) return "Chưa có dữ liệu tháng này.";

        double dailyAvgWh = usedWh / daysPassed;
        double forecastWh = dailyAvgWh * daysInMonth;
        double forecastKwh = forecastWh / 1000;
        double usedKwh     = usedWh / 1000;

        var (billSoFar,  _)      = CalculateTieredBill(usedKwh);
        var (billForecast, detail) = CalculateTieredBill(forecastKwh);

        var now2 = DateTime.Now;
        return $"Dự báo tiền điện tháng {now2.Month}/{now2.Year} ({daysPassed}/{daysInMonth} ngày đã qua):\n" +
               $"  Đã dùng: {usedKwh:F2} kWh → {billSoFar:N0} VNĐ\n" +
               $"  Trung bình: {dailyAvgWh / 1000:F3} kWh/ngày\n" +
               $"  Dự báo cả tháng: {forecastKwh:F1} kWh\n" +
               $"Chi tiết hóa đơn EVN (dự báo cả tháng):\n{detail}";
    }

    private static (double Bill, string Detail) CalculateTieredBill(double kWh)
    {
        var tiers = new (double Limit, double Price)[]
        {
            ( 50, 1984),
            (100, 2050),
            (200, 2380),
            (300, 2998),
            (400, 3350),
            (double.MaxValue, 3460)
        };

        var tierLabels = new[] { "0–50", "51–100", "101–200", "201–300", "301–400", "401+" };

        double remaining = kWh;
        double total     = 0;
        double prev      = 0;
        int    tierNum   = 0;
        var    parts     = new System.Text.StringBuilder();

        foreach (var (limit, price) in tiers)
        {
            if (remaining <= 0) break;
            double used = Math.Min(remaining, limit - prev);
            double cost = used * price;
            total    += cost;
            remaining -= used;

            if (used > 0)
                parts.Append($"  • Bậc {tierNum + 1} ({tierLabels[tierNum]} kWh): "
                           + $"{used:F1} kWh × {price:N0} đ/kWh = {cost:N0} đ\n");
            prev = limit;
            tierNum++;
        }

        double vat       = total * 0.1;
        double grandTotal = total + vat;

        parts.Append($"  • Thuế VAT 10%: {vat:N0} đ\n");
        parts.Append($"  ➜ Tổng cộng: {grandTotal:N0} VNĐ");

        return (grandTotal, parts.ToString().TrimEnd());
    }

    private static int ParseInt(JsonElement el, int defaultVal)
    {
        if (el.ValueKind == JsonValueKind.Number) return el.GetInt32();
        if (el.ValueKind == JsonValueKind.String &&
            int.TryParse(el.GetString(), out var v)) return v;
        return defaultVal;
    }

    private async Task<string> GetMonthlyComparison(
        JsonElement args, string userId, CancellationToken ct)
    {
        int months = args.TryGetProperty("months", out var m) ? ParseInt(m, 3) : 3;
        months = Math.Clamp(months, 2, 12);

        var deviceIds = await _db.Devices
            .Where(d => d.UserId == userId).Select(d => d.DeviceId).ToListAsync(ct);

        if (!deviceIds.Any()) return "Không có thiết bị nào.";

        var now = DateTime.Now;
        var results = new List<(string Label, double Wh, double Bill)>();

        for (int i = months - 1; i >= 0; i--)
        {
            var (start, end) = MonthRange(now.Year, now.Month - i < 1
                ? now.Month - i + 12 : now.Month - i);
            if (now.Month - i < 1)
                start = new DateTime(now.Year - 1, now.Month - i + 12, 1);
            end = start.AddMonths(1);

            var wh = await _db.UsagePowerLogs
                .Where(l => deviceIds.Contains(l.DeviceId) &&
                            l.CalculateDate >= start && l.CalculateDate < end)
                .SumAsync(l => l.PowerUsageWat, ct);

            var (bill, _) = CalculateTieredBill(wh / 1000);
            results.Add(($"{start:MM/yyyy}", wh, bill));
        }

        if (results.All(r => r.Wh == 0)) return "Chưa có dữ liệu điện trong các tháng này.";

        var sb = new System.Text.StringBuilder();
        sb.AppendLine($"So sánh tiêu thụ điện {months} tháng gần đây:\n");

        double maxWh = results.Max(r => r.Wh);
        foreach (var (label, wh, bill) in results)
        {
            var bar = wh > 0
                ? new string('█', (int)Math.Round(wh / maxWh * 12)) + $" {wh / 1000:F2} kWh"
                : "─ Không có dữ liệu";
            sb.AppendLine($"  {label}: {bar}");
            if (wh > 0) sb.AppendLine($"          Tiền điện: {bill:N0} VNĐ");
        }

        var nonZero = results.Where(r => r.Wh > 0).ToList();
        if (nonZero.Count >= 2)
        {
            var first = nonZero.First().Wh;
            var last  = nonZero.Last().Wh;
            var delta = (last - first) / first * 100;
            sb.AppendLine($"\nXu hướng: {(delta >= 0 ? "▲ tăng" : "▼ giảm")} {Math.Abs(delta):F1}% so với {nonZero.First().Label}");
        }

        return sb.ToString().Trim();
    }

    private async Task<string> GetYoyComparison(
        JsonElement args, string userId, CancellationToken ct)
    {
        var now = DateTime.Now;
        int month = args.TryGetProperty("month", out var mo) ? ParseInt(mo, now.Month) : now.Month;
        int year  = args.TryGetProperty("year",  out var yr) ? ParseInt(yr, now.Year)  : now.Year;

        var deviceIds = await _db.Devices
            .Where(d => d.UserId == userId).Select(d => d.DeviceId).ToListAsync(ct);

        if (!deviceIds.Any()) return "Không có thiết bị nào.";

        var (startCur, endCur) = (new DateTime(year, month, 1), new DateTime(year, month, 1).AddMonths(1));
        var (startPrev, endPrev) = (new DateTime(year - 1, month, 1), new DateTime(year - 1, month, 1).AddMonths(1));

        bool isCurrentMonth = year == now.Year && month == now.Month;
        if (isCurrentMonth) endCur = now;

        var whCur = await _db.UsagePowerLogs
            .Where(l => deviceIds.Contains(l.DeviceId) &&
                        l.CalculateDate >= startCur && l.CalculateDate < endCur)
            .SumAsync(l => l.PowerUsageWat, ct);

        var whPrev = await _db.UsagePowerLogs
            .Where(l => deviceIds.Contains(l.DeviceId) &&
                        l.CalculateDate >= startPrev && l.CalculateDate < endPrev)
            .SumAsync(l => l.PowerUsageWat, ct);

        var (billCur,  _) = CalculateTieredBill(whCur  / 1000);
        var (billPrev, _) = CalculateTieredBill(whPrev / 1000);

        var labelCur  = isCurrentMonth
            ? $"{startCur:MM/yyyy} (đến ngày {now.Day})"
            : $"{startCur:MM/yyyy}";
        var labelPrev = $"{startPrev:MM/yyyy}";

        var sb = new System.Text.StringBuilder();
        sb.AppendLine($"So sánh cùng kỳ tháng {month}:\n");
        sb.AppendLine($"  {labelCur}:  {whCur  / 1000:F2} kWh → {billCur:N0} VNĐ");
        sb.AppendLine($"  {labelPrev}: {whPrev / 1000:F2} kWh → {billPrev:N0} VNĐ");

        if (whPrev > 0)
        {
            var deltaPct  = (whCur - whPrev) / whPrev * 100;
            var deltaBill = billCur - billPrev;
            var trend     = deltaPct >= 0 ? "▲ tăng" : "▼ giảm";
            sb.AppendLine($"\nSo với cùng kỳ năm ngoái: {trend} {Math.Abs(deltaPct):F1}%");
            sb.AppendLine($"Chênh lệch tiền điện: {(deltaBill >= 0 ? "+" : "")}{deltaBill:N0} VNĐ");
        }
        else if (whCur > 0)
        {
            sb.AppendLine("\nKhông có dữ liệu cùng kỳ năm ngoái để so sánh.");
        }
        else
        {
            return "Chưa có dữ liệu cho cả hai kỳ.";
        }

        return sb.ToString().Trim();
    }

    private async Task<string> GetDevicesStatus(string userId, CancellationToken ct)
    {
        var devices = await _db.Devices
            .Where(d => d.UserId == userId).OrderBy(d => d.DeviceName).ToListAsync(ct);

        if (!devices.Any()) return "Không có thiết bị nào.";

        var on  = devices.Where(d => d.PowerStatus).Select(d => $"{d.DeviceName} ({d.Location})");
        var off = devices.Where(d => !d.PowerStatus).Select(d => $"{d.DeviceName} ({d.Location})");

        return $"Đang BẬT ({devices.Count(d => d.PowerStatus)}): {string.Join(", ", on)}\n" +
               $"Đang TẮT ({devices.Count(d => !d.PowerStatus)}): {string.Join(", ", off)}";
    }

    private static object[] GetToolDefinitions() =>
    [
        new {
            type = "function",
            function = new {
                name = "get_top_power_consumers",
                description = "Thiết bị tiêu thụ điện nhiều nhất. days=1 cho hôm nay, 7 cho tuần",
                parameters = new {
                    type = "object",
                    properties = new {
                        days  = new { type = "integer", description = "Số ngày (mặc định 7, dùng 1 cho hôm nay)" },
                        limit = new { type = "integer", description = "Số thiết bị (mặc định 5)" }
                    }
                }
            }
        },
        new {
            type = "function",
            function = new {
                name = "get_device_usage_summary",
                description = "Thống kê điện của một thiết bị cụ thể. Dùng device_id nếu có [device_id:XXX]",
                parameters = new {
                    type = "object",
                    properties = new {
                        device_id   = new { type = "string", description = "ID thiết bị từ [device_id:XXX]" },
                        device_name = new { type = "string", description = "Tên thiết bị" },
                        period      = new { type = "string", @enum = new[] { "today", "week", "month", "last30" } }
                    }
                }
            }
        },
        new {
            type = "function",
            function = new {
                name = "get_total_energy",
                description = "Tổng điện năng và tiền điện tất cả thiết bị. last_month=tháng trước (có hóa đơn đầy đủ)",
                parameters = new {
                    type = "object",
                    properties = new {
                        period = new { type = "string", @enum = new[] { "today", "week", "month", "last_month" } }
                    }
                }
            }
        },
        new {
            type = "function",
            function = new {
                name = "get_recent_warnings",
                description = "Cảnh báo AI gần đây",
                parameters = new {
                    type = "object",
                    properties = new {
                        limit = new { type = "integer", description = "Số cảnh báo (mặc định 5)" }
                    }
                }
            }
        },
        new {
            type = "function",
            function = new {
                name = "get_energy_forecast_month",
                description = "Dự báo tiền điện cuối tháng này",
                parameters = new {
                    type = "object",
                    properties = new Dictionary<string, object>(),
                    additionalProperties = false
                }
            }
        },
        new {
            type = "function",
            function = new {
                name = "get_monthly_comparison",
                description = "So sánh điện theo tháng. months='3','6','12'",
                parameters = new {
                    type = "object",
                    properties = new {
                        months = new { type = "string", @enum = new[] { "3", "6", "12" } }
                    }
                }
            }
        },
        new {
            type = "function",
            function = new {
                name = "get_yoy_comparison",
                description = "So sánh điện cùng kỳ năm ngoái",
                parameters = new {
                    type = "object",
                    properties = new {
                        month = new { type = "string", description = "Tháng, vd '8'" },
                        year  = new { type = "string", description = "Năm, vd '2026'" }
                    }
                }
            }
        },
        new {
            type = "function",
            function = new {
                name = "get_devices_status",
                description = "Trạng thái bật/tắt tất cả thiết bị",
                parameters = new {
                    type = "object",
                    properties = new Dictionary<string, object>(),
                    additionalProperties = false
                }
            }
        }
    ];
}
