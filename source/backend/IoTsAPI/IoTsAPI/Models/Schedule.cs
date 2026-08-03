using System;
using System.Collections.Generic;

namespace IoTsAPI.Models;

public partial class Schedule
{
    public string Id { get; set; } = null!;

    public string DayOfWeek { get; set; } = null!;

    public string Time { get; set; } = null!;

    public bool PowerStatus { get; set; }

    public bool Active { get; set; }

    public string? Description { get; set; }

    public string DeviceId { get; set; } = null!;
}
