using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

namespace IoTsAPI.Services;

public class OpenAiAnalysisService : IAiAnalysisService
{
    private readonly HttpClient _http;
    private readonly ILogger<OpenAiAnalysisService> _logger;
    private readonly string _model;

    private static readonly JsonSerializerOptions _jsonOpts = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower
    };

    private const string SystemPrompt =
        "Bạn là chuyên gia tư vấn tiết kiệm điện cho hệ thống IoT nhà thông minh. " +
        "Phân tích dữ liệu và đưa ra nhận xét ngắn gọn, thực tế bằng tiếng Việt. " +
        "Chỉ trả về nội dung tư vấn, không giải thích thêm, tối đa 200 ký tự.";

    private readonly string _chatUrl;

    public OpenAiAnalysisService(HttpClient http, IConfiguration config, ILogger<OpenAiAnalysisService> logger)
    {
        _http     = http;
        _logger   = logger;
        _model    = config["OpenAI:Model"] ?? "gpt-4o-mini";
        _chatUrl  = config["OpenAI:ChatUrl"] ?? "https://api.openai.com/v1/chat/completions";

        var apiKey = config["OpenAI:ApiKey"] ?? throw new InvalidOperationException("OpenAI:ApiKey not configured");
        _http.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
    }

    public Task<string> AnalyzeAnomalyAsync(AnomalyContext ctx, CancellationToken ct = default)
    {
        var historyText = string.Join(", ", ctx.RecentHistory.TakeLast(7).Select(h => $"{h.Date}: {h.Wh:F1}Wh"));
        var prompt =
            $"Thiết bị: {ctx.DeviceName} ({ctx.DeviceType}) - {ctx.Location}\n" +
            $"Hôm nay: {ctx.TodayValue:F1} Wh (Z-score: {ctx.ZScore:F1}, cao hơn {((ctx.TodayValue / ctx.BaselineAvg - 1) * 100):F0}% so với bình thường)\n" +
            $"Trung bình baseline: {ctx.BaselineAvg:F1} Wh, độ lệch chuẩn: {ctx.BaselineStdDev:F1} Wh\n" +
            $"Lịch sử 7 ngày: {historyText}\n" +
            $"Hãy phân tích nguyên nhân có thể và đưa ra 1-2 gợi ý tiết kiệm điện cụ thể.";

        return CallChatAsync(prompt, ct);
    }

    public Task<string> AnalyzeTrendAsync(TrendContext ctx, CancellationToken ct = default)
    {
        var historyText = string.Join(", ", ctx.RecentHistory.Select(h => $"{h.Date}: {h.Wh:F1}Wh"));
        var prompt =
            $"Thiết bị: {ctx.DeviceName} ({ctx.DeviceType}) - {ctx.Location}\n" +
            $"Xu hướng 7 ngày gần đây tăng trung bình {ctx.SlopePerDay:F1} Wh/ngày\n" +
            $"Mức tiêu thụ hiện tại: {ctx.CurrentAvg:F1} Wh/ngày\n" +
            $"Dữ liệu: {historyText}\n" +
            $"Dự báo tác động và đề xuất biện pháp kiểm soát xu hướng này.";

        return CallChatAsync(prompt, ct);
    }

    public Task<string> SuggestScheduleOptimizationAsync(ScheduleContext ctx, CancellationToken ct = default)
    {
        var scheduleText = string.Join("; ", ctx.Schedules.Select(s =>
            $"{s.DayOfWeek} {s.Time} {(s.IsOn ? "BẬT" : "TẮT")}"));
        var usageText = string.Join(", ", ctx.UsageByDay.TakeLast(7).Select(u => $"{u.Date}: {u.Wh:F1}Wh"));
        var prompt =
            $"Thiết bị: {ctx.DeviceName} ({ctx.DeviceType}) - {ctx.Location}\n" +
            $"Lịch hiện tại: {scheduleText}\n" +
            $"Tiêu thụ trung bình: {ctx.AvgDailyUsage:F1} Wh/ngày\n" +
            $"Dữ liệu thực tế 7 ngày: {usageText}\n" +
            $"Lịch có hợp lý không? Gợi ý điều chỉnh để tiết kiệm điện.";

        return CallChatAsync(prompt, ct);
    }

    private async Task<string> CallChatAsync(string userPrompt, CancellationToken ct)
    {
        var body = new
        {
            model = _model,
            max_tokens = 200,
            messages = new[]
            {
                new { role = "system", content = SystemPrompt },
                new { role = "user", content = userPrompt }
            }
        };

        var json = JsonSerializer.Serialize(body, _jsonOpts);
        using var req = new HttpRequestMessage(HttpMethod.Post, _chatUrl)
        {
            Content = new StringContent(json, Encoding.UTF8, "application/json")
        };

        var response = await _http.SendAsync(req, ct);
        response.EnsureSuccessStatusCode();

        var responseJson = await response.Content.ReadAsStringAsync(ct);
        using var doc = JsonDocument.Parse(responseJson);
        var content = doc.RootElement
            .GetProperty("choices")[0]
            .GetProperty("message")
            .GetProperty("content")
            .GetString() ?? string.Empty;

        return content.Trim();
    }
}
