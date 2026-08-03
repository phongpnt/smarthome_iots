using IoTsAPI.DTOs;
using IoTsAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace IoTsAPI.Controllers;

[Authorize]
[Route("api/[controller]")]
[ApiController]
public class AiScheduleController : ControllerBase
{
    private readonly AiScheduleService _service;

    public AiScheduleController(AiScheduleService service)
    {
        _service = service;
    }

    [HttpGet("suggest/{userId}")]
    public async Task<ActionResult<List<AiScheduleSuggestion>>> Suggest(
        string userId, CancellationToken ct)
    {
        try
        {
            var suggestions = await _service.SuggestAsync(userId, ct);
            return Ok(suggestions);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { error = ex.Message, type = ex.GetType().Name });
        }
    }
}
