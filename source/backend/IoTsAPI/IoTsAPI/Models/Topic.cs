using System;
using System.Collections.Generic;

namespace IoTsAPI.Models;

public partial class Topic
{
    public long TopicId { get; set; }

    public string TopicName { get; set; } = null!;

    public string DeviceId { get; set; } = null!;
}
