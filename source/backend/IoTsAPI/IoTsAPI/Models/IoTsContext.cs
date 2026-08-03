using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace IoTsAPI.Models;

public partial class IoTsContext : DbContext
{
    public IoTsContext()
    {
    }

    public IoTsContext(DbContextOptions<IoTsContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Device> Devices { get; set; }

    public virtual DbSet<Event> Events { get; set; }

    public virtual DbSet<Schedule> Schedules { get; set; }

    public virtual DbSet<Topic> Topics { get; set; }

    public virtual DbSet<UsagePowerLog> UsagePowerLogs { get; set; }

    public virtual DbSet<UserInfo> UserInfos { get; set; }

    public virtual DbSet<Warning> Warnings { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
#warning To protect potentially sensitive information in your connection string, you should move it out of source code. You can avoid scaffolding the connection string by using the Name= syntax to read it from configuration - see https:
        => optionsBuilder.UseSqlServer("Server=.\\SQLEXPRESS;Database=IoTs;Integrated Security=True;TrustServerCertificate=True");

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Device>(entity =>
        {
            entity.Property(e => e.DeviceId)
                .HasMaxLength(50)
                .IsUnicode(false);
            entity.Property(e => e.CreatedDate).HasColumnType("smalldatetime");
            entity.Property(e => e.Description).HasMaxLength(50);
            entity.Property(e => e.DeviceName).HasMaxLength(50);
            entity.Property(e => e.Location).HasMaxLength(50);
            entity.Property(e => e.Type).HasMaxLength(50);
            entity.Property(e => e.UserId)
                .HasMaxLength(50)
                .IsUnicode(false);
        });

        modelBuilder.Entity<Event>(entity =>
        {
            entity.HasKey(e => e.EventId).HasName("PK_EventIoTss");

            entity.Property(e => e.EventId)
                .HasMaxLength(50)
                .IsUnicode(false);
            entity.Property(e => e.CreatedDate).HasColumnType("smalldatetime");
            entity.Property(e => e.Value).HasMaxLength(200);
        });

        modelBuilder.Entity<Schedule>(entity =>
        {
            entity.Property(e => e.Id)
                .HasMaxLength(50)
                .IsUnicode(false);
            entity.Property(e => e.DayOfWeek)
                .HasMaxLength(7)
                .IsUnicode(false);
            entity.Property(e => e.Description).HasMaxLength(50);
            entity.Property(e => e.DeviceId)
                .HasMaxLength(50)
                .IsUnicode(false);
            entity.Property(e => e.Time)
                .HasMaxLength(5)
                .IsUnicode(false);
        });

        modelBuilder.Entity<Topic>(entity =>
        {
            entity.Property(e => e.DeviceId)
                .HasMaxLength(50)
                .IsUnicode(false);
            entity.Property(e => e.TopicName)
                .HasMaxLength(80)
                .IsUnicode(false);
        });

        modelBuilder.Entity<UsagePowerLog>(entity =>
        {
            entity.HasKey(e => e.LogId);

            entity.ToTable("UsagePowerLog");

            entity.Property(e => e.LogId)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("LogID");
            entity.Property(e => e.CalculateDate).HasColumnType("smalldatetime");
            entity.Property(e => e.DeviceId)
                .HasMaxLength(50)
                .IsUnicode(false);
            entity.Property(e => e.EndDate).HasColumnType("smalldatetime");
            entity.Property(e => e.StartDate).HasColumnType("smalldatetime");
        });

        modelBuilder.Entity<UserInfo>(entity =>
        {
            entity.HasKey(e => e.UserId).HasName("PK_Users");

            entity.Property(e => e.UserId)
                .HasMaxLength(50)
                .IsUnicode(false);
            entity.Property(e => e.CreatedDate).HasColumnType("smalldatetime");
            entity.Property(e => e.Email)
                .HasMaxLength(50)
                .IsUnicode(false);
            entity.Property(e => e.ExpireOtp)
                .HasColumnType("smalldatetime")
                .HasColumnName("ExpireOTP");
            entity.Property(e => e.FullName).HasMaxLength(50);
            entity.Property(e => e.IsUseOtp)
                .HasDefaultValue(false)
                .HasColumnName("isUseOTP");
            entity.Property(e => e.LastLogin).HasColumnType("smalldatetime");
            entity.Property(e => e.Otp)
                .HasMaxLength(6)
                .IsUnicode(false)
                .IsFixedLength()
                .HasColumnName("OTP");
            entity.Property(e => e.PassKey)
                .HasMaxLength(50)
                .IsUnicode(false);
        });

        modelBuilder.Entity<Warning>(entity =>
        {
            entity.Property(e => e.WarningId)
                .HasMaxLength(50)
                .IsUnicode(false);
            entity.Property(e => e.CreatedDate).HasColumnType("smalldatetime");
            entity.Property(e => e.DeviceId)
                .HasMaxLength(50)
                .IsUnicode(false);
            entity.Property(e => e.DeviceName).HasMaxLength(50);
            entity.Property(e => e.DeviceType).HasMaxLength(10);
            entity.Property(e => e.Location).HasMaxLength(50);
            entity.Property(e => e.NewIcon).HasDefaultValue(true);
            entity.Property(e => e.WarningContent).HasMaxLength(50);
            entity.Property(e => e.WarningTitle).HasMaxLength(50);
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
