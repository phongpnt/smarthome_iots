using System;
using System.Collections.Generic;

namespace IoTsAPI.Models;

public partial class UsagePowerLog
{
    public string LogId { get; set; } = null!;

    public DateTime CalculateDate { get; set; }

    public DateTime StartDate { get; set; }

    public DateTime EndDate { get; set; }

    public double PowerUsageWat { get; set; }

    public string DeviceId { get; set; } = null!;
}
