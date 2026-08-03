namespace IoTsAPI.DTOs;

public class AiScheduleSuggestion
{
    public string DeviceId { get; set; } = "";
    public string DeviceName { get; set; } = "";
    public string Location { get; set; } = "";
    public string Time { get; set; } = "";
    public string DayOfWeek { get; set; } = "";
    public bool PowerStatus { get; set; }
    public string Reason { get; set; } = "";
    public string Label { get; set; } = "";
}
