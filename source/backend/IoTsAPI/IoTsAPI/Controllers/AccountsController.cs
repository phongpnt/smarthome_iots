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
using System.Net.Mail;
using System.Net;

namespace IoTsAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AccountsController : ControllerBase
    {
        private readonly IoTsContext _context;

        public AccountsController(IoTsContext context)
        {
            _context = context;
        }

        [Authorize]
        [HttpGet]
        public async Task<ActionResult<IEnumerable<UserInfo>>> GetUserInfos()
        {
            return await _context.UserInfos.ToListAsync();
        }

        [Authorize]
        [HttpGet("{id}")]
        public async Task<ActionResult<UserInfo>> GetUserInfo(string id)
        {
            var userInfo = await _context.UserInfos.FindAsync(id);

            if (userInfo == null)
            {
                return NotFound();
            }

            return userInfo;
        }

        [Authorize]
        [HttpPut("{id}")]
        public async Task<IActionResult> PutUserInfo(string id, UserInfo userInfo)
        {
            if (id != userInfo.UserId)
            {
                return BadRequest();
            }

            _context.Entry(userInfo).State = EntityState.Modified;
            UserInfo user;

            try
            {
                await _context.SaveChangesAsync();
                user = userInfo;
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!UserInfoExists(id))
                {
                    return NotFound();
                }
                else
                {
                    throw;
                }
            }

            return Ok(user);
        }

        [HttpPost]
        public async Task<ActionResult<UserInfo>> PostUserInfo(UserInfo userInfo)
        {
            _context.UserInfos.Add(userInfo);
            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateException)
            {
                if (UserInfoExists(userInfo.UserId))
                {
                    return Conflict();
                }
                else
                {
                    throw;
                }
            }

            return CreatedAtAction("GetUserInfo", new { id = userInfo.UserId }, userInfo);
        }

        [Authorize]
        [HttpPost("{id}")]
        public async Task<ActionResult> CheckLogin(string id, userForLogin userInfo)
        {
            if (id != userInfo.Id)
            {
                return BadRequest();
            }
            if (userInfo == null)
            {
                return NotFound();
            }
            if (!CheckUserInfoLogin(id, userInfo.Pass))
            {
                return NotFound();
            }
            

            return Ok(userInfo);
        }

        [HttpPost("forgot/{id}")]
        public async Task<ActionResult> ForgotPass(string id)
        {
           
            if (id == null || !UserInfoExists(id))
            {
                return NotFound();
            }
            var userInfo = await _context.UserInfos.FindAsync(id);

            _context.Entry(userInfo).State = EntityState.Modified;

            Random generator = new Random();
            String otp_string = generator.Next(0, 1000000).ToString("D6");
            userInfo.Otp = otp_string;
            userInfo.ExpireOtp = DateTime.Now.AddMinutes(5);
            userInfo.IsUseOtp = false;

            try
            {
                await _context.SaveChangesAsync();

                
                
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!UserInfoExists(id))
                {
                    return NotFound();
                }
                else
                {
                    throw;
                }
            }

            
            var fromAddress = new MailAddress("phongpnt82@gmail.com", "IoTs App server");
            var toAddress = new MailAddress(userInfo.Email, userInfo.FullName);
            const string fromPassword = "algi appf blal qtet";
            const string subject = "OTP for reset pass of IoTs App";
            const string body = "OTP: ";

            var smtp = new SmtpClient
            {
                Host = "smtp.gmail.com",
                Port = 587,
                EnableSsl = true,
                DeliveryMethod = SmtpDeliveryMethod.Network,
                UseDefaultCredentials = false,
                Credentials = new NetworkCredential(fromAddress.Address, fromPassword)
            };
            using (var message = new MailMessage(fromAddress, toAddress)
            {
                Subject = subject,
                Body = body + otp_string
            })
            {
                smtp.Send(message);
            }

            return Ok();
        }

        [HttpPost("reset/{id}")]
        public async Task<ActionResult> ResetPass(string id, resetPassOTP otp)
        {

            if (id == null || otp.OTPs == null || otp.NewPass == null)
            {
                return BadRequest();
            }
            var userInfo = await _context.UserInfos.FirstOrDefaultAsync(u => (u.UserId == id || u.Email == id) && u.Otp == otp.OTPs && u.IsUseOtp == false && u.ExpireOtp >= DateTime.Now);
            if (userInfo == null)
            {
                return BadRequest();
            }

            _context.Entry(userInfo).State = EntityState.Modified;

            userInfo.PassKey = otp.NewPass;
            userInfo.Otp = null;
            userInfo.ExpireOtp = null;
            userInfo.IsUseOtp = false;

            try
            {
                await _context.SaveChangesAsync();

            }
            catch (DbUpdateConcurrencyException)
            {
                if (!UserInfoExists(id))
                {
                    return NotFound();
                }
                else
                {
                    throw;
                }
            }

            
            return Ok();
        }

        [HttpPost("verifyOTP/{id}")]
        public async Task<ActionResult> VerifyOTP(string id, string otp)
        {

            if (id == null || otp == null)
            {
                return BadRequest();
            }
            var userInfo = await _context.UserInfos.FirstOrDefaultAsync(u => (u.UserId == id || u.Email == id) && u.Otp == otp && u.IsUseOtp == false && u.ExpireOtp >= DateTime.Now);
            if (userInfo == null)
            {
                return BadRequest();
            }

            
            return Ok();
        }

        private bool UserInfoExists(string id)
        {
            return _context.UserInfos.Any(e => e.UserId == id);
        }

        private bool CheckUserInfoLogin(string id, string pass)
        {
            return _context.UserInfos.Any(u => (u.UserId == id || u.Email == id) && u.PassKey == pass && u.Active == true);
        }

        
    }
}
