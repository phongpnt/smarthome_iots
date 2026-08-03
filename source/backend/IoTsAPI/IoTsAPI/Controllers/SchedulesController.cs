using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using IoTsAPI.Models;
using Microsoft.AspNetCore.Authorization;
using IoTsAPI.Classes;

namespace IoTsAPI.Controllers
{
    [Authorize]
    [Route("api/[controller]")]
    [ApiController]
    public class SchedulesController : ControllerBase
    {
        private readonly IoTsContext _context;

        public SchedulesController(IoTsContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Schedule>>> GetSchedules()
        {
            return await _context.Schedules.ToListAsync();
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<Schedule>> GetSchedule(string id)
        {
            var schedule = await _context.Schedules.FindAsync(id);

            if (schedule == null)
            {
                return NotFound();
            }

            return schedule;
        }

        [HttpGet("device/{id}")]
        public async Task<ActionResult<List<Schedule>>> GetScheduleByDevice(string id)
        {
            var schedule = _context.Schedules.Where(y => y.DeviceId == id);

            if (schedule == null)
            {
                return NotFound();
            }

            return schedule.Cast<Schedule>().ToList();
        }

        [HttpGet("deviceallinfo/{id}")]
        public async Task<ActionResult<List<scheduleWithDeviceInfo>>> GetScheduleByDeviceWithAllInfo(string id)
        {

            var schedule = (from s in _context.Schedules
                            join d in _context.Devices on s.DeviceId equals d.DeviceId
                            where s.DeviceId == id
                            select new scheduleWithDeviceInfo
                            {
                                Id = s.Id,
                                DayOfWeek = s.DayOfWeek,
                                Time = s.Time,
                                PowerStatus = s.PowerStatus,
                                Active = s.Active,
                                Description = s.Description,
                                DeviceId = s.DeviceId,
                                DeviceName = d.DeviceName,
                                CreatedDate = d.CreatedDate,
                                Location = d.Location,
                                DeviceDescription = d.Description,
                                DevicePowerStatus = d.PowerStatus,
                                UserId = d.UserId,
                                Type = d.Type
                            }).ToList();

            if (schedule == null || !schedule.Any())
            {
                return NotFound();
            }
            

            return schedule; 
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> PutSchedule(string id, Schedule schedule)
        {
            if (id != schedule.Id)
            {
                return BadRequest();
            }

            _context.Entry(schedule).State = EntityState.Modified;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!ScheduleExists(id))
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
        public async Task<ActionResult<Schedule>> PostSchedule(Schedule schedule)
        {
            _context.Schedules.Add(schedule);
            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateException)
            {
                if (ScheduleExists(schedule.Id))
                {
                    return Conflict();
                }
                else
                {
                    throw;
                }
            }

            return CreatedAtAction("GetSchedule", new { id = schedule.Id }, schedule);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteSchedule(string id)
        {
            var schedule = await _context.Schedules.FindAsync(id);
            if (schedule == null)
            {
                return NotFound();
            }

            _context.Schedules.Remove(schedule);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        private bool ScheduleExists(string id)
        {
            return _context.Schedules.Any(e => e.Id == id);
        }
    }
}
