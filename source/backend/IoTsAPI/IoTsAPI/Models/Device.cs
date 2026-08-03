using System;
using System.Collections.Generic;

namespace IoTsAPI.Models;

public partial class Device
{
    public string DeviceId { get; set; } = null!;

    public string DeviceName { get; set; } = null!;

    public DateTime CreatedDate { get; set; }

    public string? Location { get; set; }

    public string? Description { get; set; }

    public bool PowerStatus { get; set; }

    public string UserId { get; set; } = null!;

    public string Type { get; set; } = null!;
}
