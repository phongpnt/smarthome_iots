using System;
using System.Collections.Generic;

namespace IoTsAPI.Models;

public partial class UserInfo
{
    public string UserId { get; set; } = null!;

    public string PassKey { get; set; } = null!;

    public string FullName { get; set; } = null!;

    public DateTime CreatedDate { get; set; }

    public string Email { get; set; } = null!;

    public bool Active { get; set; }

    public DateTime? LastLogin { get; set; }

    public string? Otp { get; set; }

    public DateTime? ExpireOtp { get; set; }

    public bool? IsUseOtp { get; set; }
}
