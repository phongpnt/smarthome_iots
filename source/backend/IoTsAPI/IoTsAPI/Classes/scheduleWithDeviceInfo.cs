namespace IoTsAPI.Classes
{
    public class scheduleWithDeviceInfo
    {
        
            public string Id { get; set; } = null!;
            public string DayOfWeek { get; set; } = null!;
            public string Time { get; set; } = null!;
            public bool PowerStatus { get; set; }
            public bool Active { get; set; }
            public string? Description { get; set; }
            public string DeviceId { get; set; } = null!;
            public string? DeviceName { get; set; }
            public DateTime CreatedDate { get; set; }
            public string? Location { get; set; }
            public string? DeviceDescription { get; set; }
            public bool DevicePowerStatus { get; set; }
            public string? UserId { get; set; }
            public string? Type { get; set; }
        
    }
}
