using IoTsAPI.Models;
using IoTsAPI.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using Microsoft.Extensions.Options;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();

var config = new ConfigurationBuilder()
                            .SetBasePath(Directory.GetCurrentDirectory())
                            .AddJsonFile("appsettings.json").Build();

builder.Services.AddDbContext<IoTsContext>(option =>
{
    option.UseSqlServer(config["ConnectionStrings:MyDB"]);
});

var APISecretKey = Encoding.UTF8.GetBytes(config["Jwt:Key"]);
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme).AddJwtBearer(opt =>
{
    opt.RequireHttpsMetadata = false;
    opt.SaveToken = false;
    opt.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ClockSkew = TimeSpan.Zero,

        ValidAudience = config["Jwt:Audience"],
        ValidIssuer = config["Jwt:Issuer"],
        IssuerSigningKey = new SymmetricSecurityKey(APISecretKey)

        

    };
});

builder.Services.AddHttpClient<IAiAnalysisService, OpenAiAnalysisService>();
builder.Services.AddHostedService<AiWarningBackgroundService>();
builder.Services.AddHttpClient<AiQueryService>();
builder.Services.AddHttpClient<AiScheduleService>();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

app.UseSwagger();
app.UseSwaggerUI();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
