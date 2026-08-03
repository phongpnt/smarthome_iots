using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using IoTsAPI.Models;
using IoTsAPI.Classes;
using Microsoft.AspNetCore.Authorization;
using System.Globalization;
using System.Security.Cryptography.Xml;

namespace IoTsAPI.Controllers
{
    [Authorize]
    [Route("api/[controller]")]
    [ApiController]
    public class UsagePowerLogsController : ControllerBase
    {
        private readonly IoTsContext _context;

        public UsagePowerLogsController(IoTsContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<UsagePowerLog>>> GetUsagePowerLogs()
        {
            return await _context.UsagePowerLogs.ToListAsync();
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<UsagePowerLog>> GetUsagePowerLog(string id)
        {
            var usagePowerLog = await _context.UsagePowerLogs.FindAsync(id);

            if (usagePowerLog == null)
            {
                return NotFound();
            }

            return usagePowerLog;
        }

        [HttpGet("device/{id}")]
        public async Task<ActionResult<List<UsagePowerLog>>> GetUsagePowerLogByDevice(string id)
        {
            var usagePowerLog = _context.UsagePowerLogs.Where(y => y.DeviceId == id);

            if (usagePowerLog == null)
            {
                return NotFound();
            }

            return usagePowerLog.Cast<UsagePowerLog>().ToList();
        }

        [HttpGet("powerbyday/{deviceid}")]
        public async Task<ActionResult<List<resultPowerUsageByDevice>>> GetPowerUsageByDay(string deviceid)
        {

            var temp = _context.UsagePowerLogs.Where(_ => _.DeviceId == deviceid)
                                                .OrderBy(q => q.CalculateDate)
                                                .Select(u => new
                                                {
                                                    temp_Day = u.CalculateDate.ToString("dd-MM-yyyy"),
                                                    temp_Data = u.PowerUsageWat

                                                }).ToList();

            if (temp == null || !temp.Any())
            {
                return NotFound();
            }

            var powerByDay = from y in temp
                    group y by y.temp_Day into g
                    select new resultPowerUsageByDevice
                    {
                        GroupDataKeyStart = g.First().temp_Day,
                        GroupDataKeyEnd = g.First().temp_Day,
                        Data = g.Sum(cal => cal.temp_Data),
                    };
                                            

            if (powerByDay == null || !powerByDay.Any())
            {
                return NotFound();
            }

            return powerByDay.Cast<resultPowerUsageByDevice>().ToList();
        }

        [HttpGet("powerbyweek/{deviceid}")]
        public async Task<ActionResult<List<resultPowerUsageByDevice>>> GetPowerUsageByWeek(string deviceid)
        {
            

            var temp1 = _context.UsagePowerLogs.Where(p => p.DeviceId == deviceid).ToList();

            
            if (temp1 == null || !temp1.Any())
            {
                return NotFound();
            }

            var temp2 = temp1.Where(_ => _.CalculateDate >= funcDateTimeExtension.FirstDayOfWeek(_.CalculateDate)
                                                        && _.CalculateDate <= funcDateTimeExtension.LastDayOfWeek(_.CalculateDate).AddDays(1))
                                                .OrderBy(q => q.CalculateDate)
                                                .Select(u => new
                                                {
                                                    temp_Week = funcDateTimeExtension.GetWeekOrderInYear(u.CalculateDate),
                                                    temp_Day_Start = funcDateTimeExtension.FirstDayOfWeek(u.CalculateDate).ToString("dd-MM-yyyy"),
                                                    temp_Day_End = funcDateTimeExtension.LastDayOfWeek(u.CalculateDate).ToString("dd-MM-yyyy"),
                                                    temp_Data = u.PowerUsageWat

                                                }).ToList();

            if (temp2 == null || !temp2.Any())
            {
                return NotFound();
            }

            var powerByWeek = from y in temp2
                             group y by y.temp_Week into g
                             select new resultPowerUsageByDevice
                             {
                                 GroupDataKeyStart = g.First().temp_Day_Start,
                                 GroupDataKeyEnd = g.First().temp_Day_End,
                                 Data = g.Sum(cal => cal.temp_Data),
                             };

            if (powerByWeek == null || !powerByWeek.Any())
            {
                return NotFound();
            }

            return powerByWeek.Cast<resultPowerUsageByDevice>().ToList();
        }

        [HttpGet("powerbymonth/{deviceid}")]
        public async Task<ActionResult<List<resultPowerUsageByDevice>>> GetPowerUsageByMonth(string deviceid)
        {

            var temp = _context.UsagePowerLogs.Where(_ => _.DeviceId == deviceid)
                                                .OrderBy(q => q.CalculateDate)
                                                .Select(u => new
                                                {
                                                    temp_Day = u.CalculateDate.ToString("MM-yyyy"),
                                                    temp_Data = u.PowerUsageWat

                                                }).ToList();

            if (temp == null || !temp.Any())
            {
                return NotFound();
            }

            var powerByDay = from y in temp
                             group y by y.temp_Day into g
                             select new resultPowerUsageByDevice
                             {
                                 GroupDataKeyStart = g.First().temp_Day,
                                 GroupDataKeyEnd = g.First().temp_Day,
                                 Data = g.Sum(cal => cal.temp_Data),
                             };

            if (powerByDay == null || !powerByDay.Any())
            {
                return NotFound();
            }

            return powerByDay.Cast<resultPowerUsageByDevice>().ToList();
        }

        [HttpGet("byUserRange/{userId}")]
        public async Task<ActionResult<List<UsagePowerLog>>> GetByUserRange(
            string userId,
            [FromQuery] DateTime startDate,
            [FromQuery] DateTime endDate)
        {
            var result = await (
                from p in _context.UsagePowerLogs
                join d in _context.Devices on p.DeviceId equals d.DeviceId
                where d.UserId == userId
                   && p.CalculateDate >= startDate
                   && p.CalculateDate < endDate
                orderby p.CalculateDate
                select p
            ).ToListAsync();

            return result;
        }

        [HttpGet("powerdayByUser/{userid}")]
        public async Task<ActionResult<List<resultPowerUsageByDevice>>> GetPowerUsageDayByUserid(string userid)
        {
            
            var temp = (
                            from p in _context.UsagePowerLogs
                            join d in _context.Devices on p.DeviceId equals d.DeviceId
                            where d.UserId == userid
                            orderby p.CalculateDate
                            select new
                            {
                                temp_Day = p.CalculateDate.ToString("dd-MM-yyyy"),
                                temp_Data = p.PowerUsageWat

                            }
                        ).ToList();
                                               
            
            if (temp == null || !temp.Any())
            {
                return NotFound();
            }

            var powerByDay = from y in temp
                             group y by y.temp_Day into g
                             select new resultPowerUsageByDevice
                             {
                                 GroupDataKeyStart = g.First().temp_Day,
                                 GroupDataKeyEnd = g.First().temp_Day,
                                 Data = g.Sum(cal => cal.temp_Data),
                             };

            if (powerByDay == null || !powerByDay.Any())
            {
                return NotFound();
            }

            return powerByDay.Cast<resultPowerUsageByDevice>().ToList();
        }

        [HttpGet("powerweekByUser/{userid}")]
        public async Task<ActionResult<List<resultPowerUsageByDevice>>> GetPowerUsageWeekByUserid(string userid)
        {

            var temp1 = (from p in _context.UsagePowerLogs
                         join d in _context.Devices on p.DeviceId equals d.DeviceId
                         where d.UserId == userid
                         orderby p.CalculateDate
                         select p
                        ).ToList();

            if (temp1 == null || !temp1.Any())
            {
                return NotFound();
            }

            var temp2 = temp1.Where(_ => _.CalculateDate >= funcDateTimeExtension.FirstDayOfWeek(_.CalculateDate)
                                                        && _.CalculateDate <= funcDateTimeExtension.LastDayOfWeek(_.CalculateDate).AddDays(1))
                                                .OrderBy(q => q.CalculateDate)
                                                .Select(u => new
                                                {
                                                    temp_Week = funcDateTimeExtension.GetWeekOrderInYear(u.CalculateDate),
                                                    temp_Day_Start = funcDateTimeExtension.FirstDayOfWeek(u.CalculateDate).ToString("dd-MM-yyyy"),
                                                    temp_Day_End = funcDateTimeExtension.LastDayOfWeek(u.CalculateDate).ToString("dd-MM-yyyy"),
                                                    temp_Data = u.PowerUsageWat

                                                }).ToList();

            if (temp2 == null || !temp2.Any())
            {
                return NotFound();
            }

            var powerByWeek = from y in temp2
                             group y by y.temp_Week into g
                             select new resultPowerUsageByDevice
                             {
                                 GroupDataKeyStart = g.First().temp_Day_Start,
                                 GroupDataKeyEnd = g.First().temp_Day_End,
                                 Data = g.Sum(cal => cal.temp_Data),
                             };

            if (powerByWeek == null || !powerByWeek.Any())
            {
                return NotFound();
            }

            return powerByWeek.Cast<resultPowerUsageByDevice>().ToList();
        }

        [HttpGet("powermonthByUser/{userid}")]
        public async Task<ActionResult<List<resultPowerUsageByDevice>>> GetPowerUsageMonthByUserid(string userid)
        {
            var temp = (
                            from p in _context.UsagePowerLogs
                            join d in _context.Devices on p.DeviceId equals d.DeviceId
                            where d.UserId == userid
                            orderby p.CalculateDate
                            select new
                            {
                                temp_Day = p.CalculateDate.ToString("MM-yyyy"),
                                temp_Data = p.PowerUsageWat

                            }
                        ).ToList();

            if (temp == null || !temp.Any())
            {
                return NotFound();
            }

            var powerByMonth = from y in temp
                             group y by y.temp_Day into g
                             select new resultPowerUsageByDevice
                             {
                                 GroupDataKeyStart = g.First().temp_Day,
                                 GroupDataKeyEnd = g.First().temp_Day,
                                 Data = g.Sum(cal => cal.temp_Data),
                             };

            if (powerByMonth == null || !powerByMonth.Any())
            {
                return NotFound();
            }

            return powerByMonth.Cast<resultPowerUsageByDevice>().ToList();
        }

        [HttpGet("powerToday/{deviceid}")]
        public async Task<ActionResult<List<resultPowerUsageByDevice>>> GetPowerUsageTodayByDevice(string deviceid)
        {

            var temp = _context.UsagePowerLogs.Where(_ => _.DeviceId == deviceid
                                                        )
                                                .OrderBy(q => q.CalculateDate)
                                                .Select(u => new
                                                {
                                                    temp_Day = u.CalculateDate.ToString("dd-MM-yyyy"),
                                                    temp_Data = u.PowerUsageWat

                                                }).ToList();

            if (temp == null || !temp.Any())
            {
                return NotFound();
            }

            var powerByDay = from y in temp
                             where y.temp_Day == DateTime.Now.ToString("dd-MM-yyyy")
                             group y by y.temp_Day into g
                             select new resultPowerUsageByDevice
                             {
                                 GroupDataKeyStart = g.First().temp_Day,
                                 GroupDataKeyEnd = g.First().temp_Day,
                                 Data = g.Sum(cal => cal.temp_Data),
                             };

            if (powerByDay == null || !powerByDay.Any())
            {
                return NotFound();
            }

            return powerByDay.Cast<resultPowerUsageByDevice>().ToList();
        }

        [HttpGet("powerThisWeek/{deviceid}")]
        public async Task<ActionResult<List<resultPowerUsageByDevice>>> GetPowerUsageThisWeekByDevice(string deviceid)
        {

            var temp1 = _context.UsagePowerLogs.Where(p => p.DeviceId == deviceid).ToList();

            if (temp1 == null || !temp1.Any())
            {
                return NotFound();
            }

            var temp2 = temp1.Where(_ => _.CalculateDate >= funcDateTimeExtension.FirstDayOfWeek(_.CalculateDate)
                                                        && _.CalculateDate <= funcDateTimeExtension.LastDayOfWeek(_.CalculateDate).AddDays(1))
                                                .OrderBy(q => q.CalculateDate)
                                                .Select(u => new
                                                {
                                                    temp_Week = funcDateTimeExtension.GetWeekOrderInYear(u.CalculateDate),
                                                    temp_Day_Start = funcDateTimeExtension.FirstDayOfWeek(u.CalculateDate).ToString("dd-MM-yyyy"),
                                                    temp_Day_End = funcDateTimeExtension.LastDayOfWeek(u.CalculateDate).ToString("dd-MM-yyyy"),
                                                    temp_Data = u.PowerUsageWat

                                                }).ToList();

            if (temp2 == null || !temp2.Any())
            {
                return NotFound();
            }

            var powerThisWeek = from y in temp2
                              where y.temp_Week == funcDateTimeExtension.GetWeekOrderInYear(DateTime.Now)
                              group y by y.temp_Week into g
                              select new resultPowerUsageByDevice
                              {
                                  GroupDataKeyStart = g.First().temp_Day_Start,
                                  GroupDataKeyEnd = g.First().temp_Day_End,
                                  Data = g.Sum(cal => cal.temp_Data),
                              };

            if (powerThisWeek == null || !powerThisWeek.Any())
            {
                return NotFound();
            }

            return powerThisWeek.Cast<resultPowerUsageByDevice>().ToList();
        }

        [HttpGet("powerThisMonth/{deviceid}")]
        public async Task<ActionResult<List<resultPowerUsageByDevice>>> GetPowerUsageThisMonthByDevice(string deviceid)
        {

            var temp = _context.UsagePowerLogs.Where(_ => _.DeviceId == deviceid)
                                                .OrderBy(q => q.CalculateDate)
                                                .Select(u => new
                                                {
                                                    temp_Day = u.CalculateDate.ToString("MM-yyyy"),
                                                    temp_Data = u.PowerUsageWat

                                                }).ToList();

            if (temp == null || !temp.Any())
            {
                return NotFound();
            }

            var powerByDay = from y in temp
                             where y.temp_Day == DateTime.Now.ToString("MM-yyyy")
                             group y by y.temp_Day into g
                             select new resultPowerUsageByDevice
                             {
                                 GroupDataKeyStart = g.First().temp_Day,
                                 GroupDataKeyEnd = g.First().temp_Day,
                                 Data = g.Sum(cal => cal.temp_Data),
                             };

            if (powerByDay == null || !powerByDay.Any())
            {
                return NotFound();
            }

            return powerByDay.Cast<resultPowerUsageByDevice>().ToList();
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> PutUsagePowerLog(string id, UsagePowerLog usagePowerLog)
        {
            if (id != usagePowerLog.LogId)
            {
                return BadRequest();
            }

            _context.Entry(usagePowerLog).State = EntityState.Modified;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!UsagePowerLogExists(id))
                {
                    return NotFound();
                }
                else
                {
                    throw;
                }
            }

            return NoContent();
        }

        [HttpPost]
        public async Task<ActionResult<UsagePowerLog>> PostUsagePowerLog(UsagePowerLog usagePowerLog)
        {
            _context.UsagePowerLogs.Add(usagePowerLog);
            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateException)
            {
                if (UsagePowerLogExists(usagePowerLog.LogId))
                {
                    return Conflict();
                }
                else
                {
                    throw;
                }
            }

            return CreatedAtAction("GetUsagePowerLog", new { id = usagePowerLog.LogId }, usagePowerLog);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteUsagePowerLog(string id)
        {
            var usagePowerLog = await _context.UsagePowerLogs.FindAsync(id);
            if (usagePowerLog == null)
            {
                return NotFound();
            }

            _context.UsagePowerLogs.Remove(usagePowerLog);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        private bool UsagePowerLogExists(string id)
        {
            return _context.UsagePowerLogs.Any(e => e.LogId == id);
        }

        

    }
}
