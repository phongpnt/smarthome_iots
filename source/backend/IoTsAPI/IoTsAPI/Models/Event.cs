using System;
using System.Collections.Generic;

namespace IoTsAPI.Models;

public partial class Event
{
    public string EventId { get; set; } = null!;

    public DateTime CreatedDate { get; set; }

    public string Value { get; set; } = null!;

    public long TopicId { get; set; }
}
