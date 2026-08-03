namespace IoTsAPI.DTOs;

public record AiQueryRequest(
    string Question,
    string UserId
);

public record AiQueryResponse(
    string Answer,
    bool Success,
    string? Error = null
);
