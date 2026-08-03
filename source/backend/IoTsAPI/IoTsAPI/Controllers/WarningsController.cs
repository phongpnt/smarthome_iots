using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using IoTsAPI.Models;
using Microsoft.AspNetCore.Authorization;

namespace IoTsAPI.Controllers
{
    [Authorize]
    [Route("api/[controller]")]
    [ApiController]
    public class WarningsController : ControllerBase
    {
        private readonly IoTsContext _context;

        public WarningsController(IoTsContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Warning>>> GetWarnings()
        {
            return await _context.Warnings.ToListAsync();
        }

        [HttpGet("device/{deviceid}")]
        public async Task<ActionResult<List<Warning>>> GetWarningByDevice(string deviceid)
        {
            var warning = _context.Warnings.Where(_ => _.DeviceId == deviceid).OrderByDescending(_ => _.CreatedDate);

            if (warning == null)
            {
                return NotFound();
            }

            return warning.Cast<Warning>().ToList();
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<Warning>> GetWarning(string id)
        {
            var warning = await _context.Warnings.FindAsync(id);

            if (warning == null)
            {
                return NotFound();
            }

            return warning;
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> PutWarning(string id, Warning warning)
        {
            if (id != warning.WarningId)
            {
                return BadRequest();
            }

            _context.Entry(warning).State = EntityState.Modified;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!WarningExists(id))
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
        public async Task<ActionResult<Warning>> PostWarning(Warning warning)
        {
            _context.Warnings.Add(warning);
            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateException)
            {
                if (WarningExists(warning.WarningId))
                {
                    return Conflict();
                }
                else
                {
                    throw;
                }
            }

            return CreatedAtAction("GetWarning", new { id = warning.WarningId }, warning);
        }

        [HttpPatch("{id}/newicon")]
        public async Task<IActionResult> PatchNewIcon(string id, [FromBody] bool newIcon)
        {
            var warning = await _context.Warnings.FindAsync(id);
            if (warning == null) return NotFound();

            warning.NewIcon = newIcon;
            await _context.SaveChangesAsync();
            return NoContent();
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteWarning(string id)
        {
            var warning = await _context.Warnings.FindAsync(id);
            if (warning == null)
            {
                return NotFound();
            }

            _context.Warnings.Remove(warning);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        private bool WarningExists(string id)
        {
            return _context.Warnings.Any(e => e.WarningId == id);
        }
    }
}
