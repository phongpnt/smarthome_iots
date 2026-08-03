using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using IoTsAPI.DTOs;
using IoTsAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace IoTsAPI.Services;

public class AiScheduleService
{
    private readonly IoTsContext _db;
    private readonly HttpClient _http;
    private readonly ILogger<AiScheduleService> _logger;
    private readonly string _model;
    private readonly string _chatUrl;

    private static readonly JsonSerializerOptions _jsonOpts = new()
    {
        PropertyNamingPolicy        = JsonNamingPolicy.CamelCase,
        PropertyNameCaseInsensitive = true,
        DefaultIgnoreCondition      =
            System.Text.Json.Serialization.JsonIgnoreCondition.WhenWritingNull
    };

    public AiScheduleService(
        IoTsContext db, HttpClient http,
        IConfiguration config, ILogger<AiScheduleService> logger)
    {
        _db     = db;
        _http   = http;
        _logger = logger;
        _model  = config["OpenAI:Model"]   ?? "llama-3.3-70b-versatile";
        _chatUrl = config["OpenAI:ChatUrl"] ?? "https://api.groq.com/openai/v1/chat/completions";

        var apiKey = config["OpenAI:ApiKey"]
            ?? throw new InvalidOperationException("OpenAI:ApiKey not configured");
        _http.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", apiKey);
    }

    public async Task<List<AiScheduleSuggestion>> SuggestAsync(
        string userId, CancellationToken ct = default)
    {
        var devices = await _db.Devices
            .Where(d => d.UserId == userId)
            .ToListAsync(ct);
        if (!devices.Any())
        {
            _logger.LogWarning("[AiSchedule] No devices for userId={UserId}", userId);
            return [];
        }

        var since = DateTime.Now.AddDays(-90);
        var logs  = await (
            from log in _db.UsagePowerLogs
            join dev in _db.Devices on log.DeviceId equals dev.DeviceId
            where dev.UserId == userId && log.CalculateDate >= since
            select log
        ).ToListAsync(ct);

        _logger.LogInformation("[AiSchedule] userId={UserId} → {DeviceCount} devices, {LogCount} logs (90d)",
            userId, devices.Count, logs.Count);

        if (!logs.Any()) return [];

        var deviceMap    = devices.ToDictionary(d => d.DeviceId);
        var patternLines = new List<string>();

        foreach (var grp in logs.GroupBy(l => l.DeviceId))
        {
            if (!deviceMap.TryGetValue(grp.Key, out var dev)) continue;
            var sessions = grp.ToList();

            var onHour   = sessions.GroupBy(s => GetStartDt(s).Hour)
                                   .OrderByDescending(g => g.Count()).First().Key;
            var avgOnMin = (int)sessions.Average(s => GetStartDt(s).Minute);

            var offHour   = sessions.GroupBy(s => GetEndDt(s).Hour)
                                    .OrderByDescending(g => g.Count()).First().Key;
            var avgOffMin = (int)sessions.Average(s => GetEndDt(s).Minute);

            avgOnMin  = (int)Math.Round(avgOnMin  / 5.0) * 5 % 60;
            avgOffMin = (int)Math.Round(avgOffMin / 5.0) * 5 % 60;

            var activeDays = sessions
                .Select(s => GetStartDt(s).DayOfWeek == DayOfWeek.Sunday
                    ? 7 : (int)GetStartDt(s).DayOfWeek)
                .GroupBy(d => d)
                .OrderByDescending(g => g.Count())
                .Select(g => g.Key)
                .OrderBy(d => d)
                .ToList();
            var dayStr = activeDays.Any() ? string.Join("", activeDays) : "1234567";

            _logger.LogInformation(
                "[AiSchedule] {Name}: {Count} sessions, on={On}, off={Off}, days={Days}",
                dev.DeviceName, sessions.Count,
                $"{onHour:D2}:{avgOnMin:D2}", $"{offHour:D2}:{avgOffMin:D2}", dayStr);

            patternLines.Add(
                $"id={grp.Key};name={dev.DeviceName ?? "?"};type={dev.Type ?? "other"};" +
                $"location={dev.Location ?? "?"};sessions={sessions.Count};" +
                $"on={onHour:D2}:{avgOnMin:D2};off={offHour:D2}:{avgOffMin:D2};" +
                $"days={dayStr}");
        }

        if (!patternLines.Any()) return [];

        return await CallGroqAsync(patternLines, ct);
    }

    private async Task<List<AiScheduleSuggestion>> CallGroqAsync(
        List<string> patterns, CancellationToken ct)
    {
        var patternBlock = string.Join("\n", patterns);

        var systemMsg =
            "Bạn là AI chuyên tối ưu lịch smart home. " +
            "LUÔN trả về JSON hợp lệ theo đúng schema yêu cầu, KHÔNG thêm text khác.";

        var userMsg = $$"""
            Dựa trên thói quen sử dụng thiết bị dưới đây (30 ngày gần đây),
            hãy đề xuất lịch tự động phù hợp.

            DỮ LIỆU:
            {{patternBlock}}

            Trả về JSON object có key "suggestions" là array, mỗi phần tử:
            {
              "deviceId": "...",
              "deviceName": "...",
              "location": "...",
              "time": "HH:mm",
              "dayOfWeek": "1234567",
              "powerStatus": true,
              "reason": "...",
              "label": "..."
            }

            Quy tắc:
            - Mỗi thiết bị: tạo 1 lịch BẬT + 1 lịch TẮT dựa trên on= và off= trong dữ liệu
            - LUÔN tạo gợi ý cho TẤT CẢ thiết bị có trong dữ liệu đầu vào
            - time: dùng đúng giờ on=/off= từ dữ liệu, ví dụ "07:30", "22:00"
            - dayOfWeek: dùng chuỗi days= từ dữ liệu, ví dụ "12345" cho ngày thường
            - reason: 1 câu tiếng Việt, đề cập số phiên thực tế (sessions=)
            - label: tên ngắn gọn tiếng Việt, ví dụ "Bật máy lạnh buổi tối"
            - deviceId phải khớp chính xác với id= trong dữ liệu đầu vào
            - KHÔNG bỏ qua bất kỳ thiết bị nào trong dữ liệu
            """;

        var body = new
        {
            model  = _model,
            messages = new[]
            {
                new { role = "system", content = systemMsg },
                new { role = "user",   content = userMsg }
            },
            response_format = new { type = "json_object" },
            max_tokens      = 1500,
            temperature     = 0.3
        };

        var json    = JsonSerializer.Serialize(body, _jsonOpts);
        int[] delays = [6000, 12000];

        for (int attempt = 0; attempt < 3; attempt++)
        {
            using var req = new HttpRequestMessage(HttpMethod.Post, _chatUrl)
            {
                Content = new StringContent(json, Encoding.UTF8, "application/json")
            };

            var res = await _http.SendAsync(req, ct);

            if ((int)res.StatusCode == 429 && attempt < 2)
            {
                _logger.LogWarning("Rate limit (attempt {A}) — waiting {D}ms", attempt + 1, delays[attempt]);
                await Task.Delay(delays[attempt], ct);
                continue;
            }

            res.EnsureSuccessStatusCode();
            var responseJson = await res.Content.ReadAsStringAsync(ct);
            return ParseSuggestions(responseJson);
        }

        return [];
    }

    private static DateTime GetStartDt(UsagePowerLog l) =>
        l.StartDate.Year > 1900 ? l.StartDate : l.CalculateDate;

    private static DateTime GetEndDt(UsagePowerLog l) =>
        l.EndDate.Year > 1900 ? l.EndDate : l.CalculateDate.AddHours(1);

    private List<AiScheduleSuggestion> ParseSuggestions(string responseJson)
    {
        try
        {
            var root    = JsonNode.Parse(responseJson);
            var content = root?["choices"]?[0]?["message"]?["content"]?.GetValue<string>();
            if (string.IsNullOrEmpty(content)) return [];

            var parsed = JsonNode.Parse(content);
            var arr    = parsed?["suggestions"]?.AsArray();
            if (arr == null) return [];

            var result = new List<AiScheduleSuggestion>();
            foreach (var item in arr)
            {
                if (item == null) continue;
                result.Add(new AiScheduleSuggestion
                {
                    DeviceId    = item["deviceId"]?.GetValue<string>()    ?? "",
                    DeviceName  = item["deviceName"]?.GetValue<string>()  ?? "",
                    Location    = item["location"]?.GetValue<string>()    ?? "",
                    Time        = item["time"]?.GetValue<string>()        ?? "08:00",
                    DayOfWeek   = item["dayOfWeek"]?.GetValue<string>()   ?? "1234567",
                    PowerStatus = item["powerStatus"]?.GetValue<bool>()   ?? true,
                    Reason      = item["reason"]?.GetValue<string>()      ?? "",
                    Label       = item["label"]?.GetValue<string>()       ?? "",
                });
            }
            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to parse AI schedule suggestions");
            return [];
        }
    }
}
