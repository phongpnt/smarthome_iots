from machine import Pin, I2C
import time
import gc
import _thread
from config_loader import get_config

UNIT_ACMEASURE_ADDR = 0x42
UNIT_ACMEASURE_VOLTAGE_STR_REG      = 0x00  # 7 bytes "XXXX.YY"
UNIT_ACMEASURE_CURRENT_STR_REG      = 0x10  # 7 bytes "XXXX.YY"
UNIT_ACMEASURE_POWER_STR_REG        = 0x20  # 7 bytes "XXXX.YY"
UNIT_ACMEASURE_APPARENT_STR_REG     = 0x30  # 7 bytes "XXXX.YY"
UNIT_ACMEASURE_POWERFACTOR_STR_REG  = 0x40  # 4 bytes "X.YY"
UNIT_ACMEASURE_KWH_STR_REG          = 0x50  # 11 bytes
UNIT_ACMEASURE_VOLTAGE_BYTE_REG     = 0x60  # uint16 LE
UNIT_ACMEASURE_CURRENT_BYTE_REG     = 0x70  # uint16 LE
UNIT_ACMEASURE_POWER_BYTE_REG       = 0x80  # uint32 LE
UNIT_ACMEASURE_VOLTAGE_COEFF_REG    = 0xC0  # 1 byte (0=uncalibrated → reads 0)
UNIT_ACMEASURE_CURRENT_COEFF_REG    = 0xD0  # 1 byte
UNIT_ACMEASURE_SAVE_COEFF_REG       = 0xE0  # write 0x01 to save to flash
UNIT_ACMEASURE_DATA_READY_REG       = 0xFC  # 1 byte: 1=ready
UNIT_ACMEASURE_FIRM_VER_REG         = 0xFE  # 1 byte: firmware version

i2c = None
ac_measure = None
_hw_init_failed = False  # Tránh retry liên tục khi sensor không tìm thấy

def init_hardware():
    global i2c, ac_measure, _hw_init_failed
    if i2c is not None:
        return  # Đã khởi tạo
    if _hw_init_failed:
        return  # Đã thử và thất bại, không retry

    config = get_config()
    device_config = config.get('device', {})
    scl_pin = device_config.get('i2c_scl_pin')
    sda_pin = device_config.get('i2c_sda_pin')

    if scl_pin is None or sda_pin is None:
        print("[HW] Warning: I2C pins not configured. AC Measurement disabled.")
        return

    try:
        print(f"[HW] Initializing I2C: SCL={scl_pin}, SDA={sda_pin}")
        i2c = I2C(1, scl=Pin(scl_pin), sda=Pin(sda_pin), freq=100000)
        devices = i2c.scan()
        print(f"[HW] I2C scan found: {[hex(d) for d in devices]}")
        if UNIT_ACMEASURE_ADDR in devices:
            ac_measure = UNIT_ACMEASURE(i2c)
            print(f"[HW] UNIT_ACMEASURE initialized at {hex(UNIT_ACMEASURE_ADDR)}.")
        else:
            print(f"[HW] Warning: UNIT_ACMEASURE not found at {hex(UNIT_ACMEASURE_ADDR)}.")
            i2c = None
            _hw_init_failed = True  # Không retry nữa cho đến khi reboot
    except Exception as e:
        i2c = None
        ac_measure = None
        _hw_init_failed = True
        print(f"[HW] Failed to init I2C/AC Measure: {e}")

class UNIT_ACMEASURE:

    def __init__(self, i2c_obj, addr=UNIT_ACMEASURE_ADDR):
        self.i2c = i2c_obj
        self.addr = addr

    def _read_float_str(self, reg, n):
        try:
            data = self.i2c.readfrom_mem(self.addr, reg, n)
            s = ''.join(chr(b) for b in data if 32 <= b <= 126).strip()
            return float(s) if s else 0.0
        except Exception as e:
            print(f"[HW] I2C read err reg={hex(reg)}: {e}")
        return 0.0

    def is_data_ready(self):
        try:
            return self.i2c.readfrom_mem(self.addr, UNIT_ACMEASURE_DATA_READY_REG, 1)[0] == 1
        except:
            return False

    def get_voltage(self):
        return self._read_float_str(UNIT_ACMEASURE_VOLTAGE_STR_REG, 4)

    def get_current(self):
        return self._read_float_str(UNIT_ACMEASURE_CURRENT_STR_REG, 4)

    def get_power(self):
        return self._read_float_str(UNIT_ACMEASURE_POWER_STR_REG, 4)

    def get_power_factor(self):
        return self._read_float_str(UNIT_ACMEASURE_POWERFACTOR_STR_REG, 4)

    def debug_raw(self):
        try:
            fw  = self.i2c.readfrom_mem(self.addr, UNIT_ACMEASURE_FIRM_VER_REG, 1)[0]
            rdy = self.i2c.readfrom_mem(self.addr, UNIT_ACMEASURE_DATA_READY_REG, 1)[0]
            vc  = self.i2c.readfrom_mem(self.addr, UNIT_ACMEASURE_VOLTAGE_COEFF_REG, 1)[0]
            ic  = self.i2c.readfrom_mem(self.addr, UNIT_ACMEASURE_CURRENT_COEFF_REG, 1)[0]
            print(f"[AC] FW={fw} DataReady={rdy} V_coeff={vc} I_coeff={ic}")
        except Exception as e:
            print(f"[AC] meta err: {e}")
        v  = self.get_voltage()
        p  = self.get_power()
        pf = self.get_power_factor()
        c  = self.get_current()
        if c == 0.0 and v > 0 and pf > 0 and p > 0:
            c = round(p / (v * pf), 3)
        print(f"[AC] V={v}V  I={c}A  P={p}W  PF={pf}")

    def debug_raw_registers(self):
        import struct
        print("[SCAN] === AC Measure Register Scan ===")
        try:
            block = self.i2c.readfrom_mem(self.addr, 0x00, 96)
            print(f"[SCAN] Raw block 0x00-0x5F ({len(block)} bytes):")
            for i in range(0, len(block), 4):
                chunk = block[i:i+4]
                u16a = chunk[0] | (chunk[1] << 8)
                u16b = chunk[2] | (chunk[3] << 8)
                f32  = struct.unpack('<f', chunk)[0]
                print(f"  reg=0x{i:02X}: bytes={[hex(b) for b in chunk]}"
                      f"  u16[0]={u16a}  u16[1]={u16b}  f32={f32:.4f}")
        except Exception as e:
            print(f"[SCAN] Block read failed: {e}, trying individual regs...")
            for reg in range(0, 0x60, 4):
                try:
                    data = self.i2c.readfrom_mem(self.addr, reg, 4)
                    u16 = data[0] | (data[1] << 8)
                    f32 = struct.unpack('<f', data)[0]
                    print(f"  reg=0x{reg:02X}: {[hex(b) for b in data]}"
                          f"  u16={u16}  f32={f32:.4f}")
                except Exception as e2:
                    print(f"  reg=0x{reg:02X}: ERR {e2}")

_relay_pin_number = None
_main_relay_obj = None

def get_relay_pin():
    global _relay_pin_number
    if _relay_pin_number is None:
        config = get_config()
        device_config = config.get('device', {})
        _relay_pin_number = device_config.get('relay_pin')
        if _relay_pin_number is None:
            print("[HW] Warning: 'relay_pin' not configured.")
    return _relay_pin_number

def get_main_relay_obj():
    global _main_relay_obj
    if _main_relay_obj is None:
        pin_num = get_relay_pin()
        if pin_num is not None:
            try:
                _main_relay_obj = Pin(pin_num, Pin.OUT)
                _main_relay_obj.value(0)  # Khởi tạo OFF
                print(f"[HW] Relay Pin object created: GPIO{pin_num}.")
            except Exception as e:
                print(f"[HW] Error creating relay Pin on GPIO{pin_num}: {e}")
                _main_relay_obj = None
        else:
            print("[HW] Cannot create relay: pin not configured.")
    return _main_relay_obj

def control_relay(relay_pin_obj, state):
    if relay_pin_obj is None:
        print("[HW] control_relay: relay_pin_obj is None!")
        return
    try:
        target = 1 if state == "on" else 0
        before = relay_pin_obj.value()
        relay_pin_obj.value(target)
        after = relay_pin_obj.value()
        print(f"[HW] Relay pin=GPIO{_relay_pin_number} | {before} → {after} | cmd={state.upper()}")
        if before == after and before != target:
            print(f"[HW] WARNING: Relay pin did not change! Possible hardware issue.")
    except Exception as e:
        print(f"[HW] Error controlling relay: {e}")

def test_relay(times=3, delay_ms=500):
    import time
    relay_obj = get_main_relay_obj()
    if relay_obj is None:
        print("[TEST] Relay not available.")
        return
    print(f"[TEST] Relay test on GPIO{_relay_pin_number}: {times} cycles, {delay_ms}ms interval")
    for i in range(times):
        relay_obj.value(1)
        print(f"[TEST] Cycle {i+1}: ON  → pin={relay_obj.value()}")
        time.sleep_ms(delay_ms)
        relay_obj.value(0)
        print(f"[TEST] Cycle {i+1}: OFF → pin={relay_obj.value()}")
        time.sleep_ms(delay_ms)
    print("[TEST] Done.")

_power_thread_running = False
_last_thread_attempt_time = 0  # Cooldown tránh spam start_new_thread

_total_energy_wh_lifetime = 0.0  # Tích lũy qua tất cả các relay cycle
_session_energy_wh = 0.0  # Chỉ tính trong lần bật hiện tại

_relay_on_time = None  # localtime() tuple khi relay ON

_energy_lock = _thread.allocate_lock()

def _do_register_scan(sensor, verbose=False):
    import struct as _struct

    def _p(msg):
        if verbose:
            print(msg)

    _p("[SCAN] ===== I2C Register Scan =====")
    _p("[SCAN] -- readfrom_mem approach --")
    for reg in range(0, 0x54, 4):
        try:
            d = sensor.i2c.readfrom_mem(sensor.addr, reg, 4)
            if verbose:
                u16 = d[0] | (d[1] << 8)
                f32 = _struct.unpack('<f', d)[0]
                print(f"[SCAN] 0x{reg:02X}: bytes={[hex(b) for b in d]} u16={u16} f32={f32:.3f}")
        except Exception as e:
            _p(f"[SCAN] 0x{reg:02X}: ERR {e}")
    _p("[SCAN] -- writeto+readfrom approach --")
    for reg in [0x00, 0x02, 0x04, 0x06, 0x08]:
        try:
            sensor.i2c.writeto(sensor.addr, bytes([reg]))
            d = sensor.i2c.readfrom(sensor.addr, 4)
            if verbose:
                u16 = d[0] | (d[1] << 8)
                f32 = _struct.unpack('<f', d)[0]
                print(f"[SCAN] w+r 0x{reg:02X}: bytes={[hex(b) for b in d]} u16={u16} f32={f32:.3f}")
        except Exception as e:
            _p(f"[SCAN] w+r 0x{reg:02X}: ERR {e}")
    _p("[SCAN] -- byte + coeff registers 0x60-0xFF --")
    for reg, nbytes, label in [
        (0x60, 2, 'V_byte uint16'),
        (0x70, 2, 'I_byte uint16'),
        (0x80, 4, 'P_byte uint32'),
        (0x90, 4, 'ApP_byte uint32'),
        (0xA0, 1, 'PF_byte u8'),
        (0xB0, 4, 'kWh uint32'),
        (0xC0, 1, 'V_coeff u8'),
        (0xD0, 1, 'I_coeff u8'),
        (0xFC, 1, 'DataReady'),
        (0xFE, 1, 'FW_ver'),
        (0xFF, 1, 'I2C_addr'),
    ]:
        try:
            d = sensor.i2c.readfrom_mem(sensor.addr, reg, nbytes)
            if verbose:
                raw = [hex(b) for b in d]
                val = d[0] if nbytes == 1 else (
                    _struct.unpack('<H', d)[0] if nbytes == 2 else
                    _struct.unpack('<I', d)[0])
                print(f"[SCAN] 0x{reg:02X} ({label}): {raw} = {val}")
        except Exception as e:
            _p(f"[SCAN] 0x{reg:02X} ({label}): ERR {e}")
    _p("[SCAN] ===== End Scan =====")

def calculate_total_power_thread():
    global _power_thread_running, _total_energy_wh_lifetime, _session_energy_wh

    relay_obj = get_main_relay_obj()
    ac_measure_obj = ac_measure

    if ac_measure_obj is None or relay_obj is None:
        print("[Power] Cannot start: AC Measure or Relay not available.")
        _power_thread_running = False
        return

    print("[Power] Measurement thread started.")

    _do_register_scan(ac_measure_obj, verbose=False)

    with _energy_lock:
        _session_energy_wh = 0.0

    last_measurement_time = time.time()
    last_gc_time = last_measurement_time
    last_debug_time = last_measurement_time
    _zero_count = 0  # đếm số lần liên tiếp đọc được 0W
    _ZERO_THRESHOLD = 10  # re-prime sau 10 lần 0 liên tiếp (~10s)
    _reprime_attempts = 0
    _MAX_REPRIME = 2  # thử tối đa 2 lần, sau đó dừng hẳn

    while _power_thread_running:
        if relay_obj.value() == 0:
            print("[Power] Relay turned OFF externally. Thread stopping.")
            break

        current_time = time.time()
        delta_time = current_time - last_measurement_time

        if delta_time >= 1.0:
            try:
                power_w = ac_measure_obj.get_power()  # Active power W từ sensor

                if power_w == 0.0:
                    _zero_count += 1
                    if _zero_count >= _ZERO_THRESHOLD:
                        if _reprime_attempts < _MAX_REPRIME:
                            _reprime_attempts += 1
                            print(f"[Power] Sensor lost data. Re-prime attempt {_reprime_attempts}/{_MAX_REPRIME}...")
                            _do_register_scan(ac_measure_obj, verbose=False)
                            _zero_count = 0
                            print("[Power] Re-prime done. Waiting for data...")
                        else:
                            print("[Power] Sensor hardware fault. Measurement suspended. Power cycle sensor to restore.")
                            _zero_count = 0  # reset để không spam log
                            _ZERO_THRESHOLD = 9999  # không thử lại nữa
                else:
                    _zero_count = 0
                    _reprime_attempts = 0  # reset attempt count khi sensor hoạt động trở lại

                energy_interval = power_w * (delta_time / 3600.0)
                with _energy_lock:
                    _session_energy_wh += energy_interval
                    _total_energy_wh_lifetime += energy_interval

                last_measurement_time = current_time
            except Exception as e:
                print(f"[Power] Measurement error: {e}")
                time.sleep(2)

        if current_time - last_debug_time >= 10:
            ac_measure_obj.debug_raw()
            last_debug_time = current_time

        if current_time - last_gc_time >= 60:
            gc.collect()
            last_gc_time = current_time

        time.sleep(0.1)

    _power_thread_running = False
    with _energy_lock:
        session = _session_energy_wh
    print(f"[Power] Thread stopped. Session energy: {session:.4f} Wh | "
          f"Lifetime: {_total_energy_wh_lifetime:.4f} Wh")

def get_relay_on_time():
    return _relay_on_time

def start_power_measurement():
    global _power_thread_running, _relay_on_time, _last_thread_attempt_time
    if _power_thread_running:
        return

    now = time.time()
    if now - _last_thread_attempt_time < 5:
        return
    _last_thread_attempt_time = now

    _relay_on_time = time.localtime(time.time() + 7 * 3600)

    init_hardware()
    relay_obj = get_main_relay_obj()
    if ac_measure is None or relay_obj is None:
        print("[Power] AC Measure not available. Relay ON time recorded but no measurement thread.")
        return

    _power_thread_running = True
    try:
        _thread.start_new_thread(calculate_total_power_thread, ())
    except Exception as e:
        print(f"[Power] Failed to start thread: {e}")
        _power_thread_running = False

def stop_power_measurement():
    global _power_thread_running
    _power_thread_running = False

def get_session_energy():
    with _energy_lock:
        return _session_energy_wh

def get_total_energy():
    with _energy_lock:
        return _total_energy_wh_lifetime

def is_power_measurement_running():
    return _power_thread_running
