using System;
using System.Collections.Generic;

namespace IoTsAPI.Models;

public partial class Warning
{
    public string WarningId { get; set; } = null!;

    public DateTime CreatedDate { get; set; }

    public string WarningTitle { get; set; } = null!;

    public string WarningContent { get; set; } = null!;

    public bool NewIcon { get; set; }

    public string DeviceId { get; set; } = null!;

    public string DeviceName { get; set; } = null!;

    public string Location { get; set; } = null!;

    public string? DeviceType { get; set; }

    public string? WarningSource { get; set; }

    public double? AnomalyScore { get; set; }
}
