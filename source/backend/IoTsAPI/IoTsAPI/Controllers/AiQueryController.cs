using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using IoTsAPI.DTOs;
using IoTsAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace IoTsAPI.Controllers;

[Authorize]
[Route("api/[controller]")]
[ApiController]
public class AiQueryController : ControllerBase
{
    private readonly AiQueryService _aiQuery;
    private readonly IConfiguration _config;
    private readonly IHttpClientFactory _httpFactory;

    public AiQueryController(AiQueryService aiQuery, IConfiguration config,
        IHttpClientFactory httpFactory)
    {
        _aiQuery     = aiQuery;
        _config      = config;
        _httpFactory = httpFactory;
    }

    [HttpPost("query")]
    public async Task<ActionResult<AiQueryResponse>> Query(
        [FromBody] AiQueryRequest request,
        CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(request.Question))
            return BadRequest(new AiQueryResponse("", false, "Question is required"));
        if (string.IsNullOrWhiteSpace(request.UserId))
            return BadRequest(new AiQueryResponse("", false, "UserId is required"));

        var result = await _aiQuery.QueryAsync(request.Question, request.UserId, ct);

        if (!result.Success)
            return Ok(new AiQueryResponse(
                "Tôi chưa thể truy cập dữ liệu lúc này. Vui lòng thử lại sau.", true));

        return Ok(result);
    }

    [AllowAnonymous]
    [HttpGet("test")]
    public async Task<IActionResult> Test(CancellationToken ct)
    {
        var apiKey = _config["OpenAI:ApiKey"] ?? "(not set)";
        var model  = _config["OpenAI:Model"]  ?? "(not set)";
        var keyPreview = apiKey.Length > 12
            ? apiKey[..8] + "..." + apiKey[^4..]
            : apiKey;

        var chatUrl = _config["OpenAI:ChatUrl"] ?? "https://api.groq.com/openai/v1/chat/completions";

        try
        {
            using var client = _httpFactory.CreateClient();
            client.DefaultRequestHeaders.Authorization =
                new AuthenticationHeaderValue("Bearer", apiKey);

            var body = JsonSerializer.Serialize(new
            {
                model,
                messages = new[] { new { role = "user", content = "Say: OK" } },
                max_tokens = 5
            });

            using var req = new HttpRequestMessage(HttpMethod.Post, chatUrl)
            {
                Content = new StringContent(body, Encoding.UTF8, "application/json")
            };

            var res = await client.SendAsync(req, ct);
            var responseBody = await res.Content.ReadAsStringAsync(ct);

            return Ok(new
            {
                KeyPreview  = keyPreview,
                Model       = model,
                ChatUrl     = chatUrl,
                HttpStatus  = (int)res.StatusCode,
                Success     = res.IsSuccessStatusCode,
                OpenAiReply = responseBody[..Math.Min(500, responseBody.Length)]
            });
        }
        catch (Exception ex)
        {
            return Ok(new
            {
                KeyPreview = keyPreview,
                Model      = model,
                Error      = ex.GetType().Name,
                Message    = ex.Message
            });
        }
    }
}
