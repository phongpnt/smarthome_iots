import time
import machine
import gc
import ujson as json

from config_loader import get_config
from wifi_manage import (connect_wifi, disconnect_wifi, is_wifi_connected,
                          get_connected_mac, reconnect_wifi_with_backoff, get_rssi)
from mqtt import (connect_mqtt, check_mqtt_messages, disconnect_mqtt,
                   publish_message, reset_reconnect_cooldown)
import mqtt as mqtt_module  # Để set hook on_schedule_update
from access_apiserver import (get_token, fetch_json_data_schedule,
                               load_schedule_from_flash, save_schedule_to_flash,
                               post_power_log)
from smartplug import (init_hardware, get_main_relay_obj, control_relay,
                        start_power_measurement, stop_power_measurement,
                        is_power_measurement_running, get_total_energy,
                        get_session_energy, get_relay_on_time)
from data_logger import DataLogger
from ota import check_update, apply_update, should_check_update, get_current_version

TELEMETRY_TOPIC = "smartplug/telemetry"
LOG_TOPIC = "smartplug/log"
STATUS_TOPIC = "smartplug/status_report"
TELEMETRY_INTERVAL_SEC = 1
STATUS_INTERVAL_SEC = 60
GC_INTERVAL_SEC = 60
SCHEDULE_CHECK_INTERVAL_SEC = 15  # Kiểm tra schedule mỗi 15 giây (trễ tối đa 15s)
SCHEDULE_REFRESH_INTERVAL_SEC = 3600  # Fetch lại từ API mỗi 1 giờ

_schedule_data = None

def _on_schedule_update_callback(new_schedule):
    global _schedule_data
    _schedule_data = new_schedule
    print(f"[Schedule] In-memory schedule updated via MQTT: {len(new_schedule)} items.")

_TZ_OFFSET_SEC = 7 * 3600  # UTC+7 (Indochina Time)

def _localtime_ict():
    return time.localtime(time.time() + _TZ_OFFSET_SEC)

def _sync_ntp():
    try:
        import ntptime
        ntptime.settime()
        t = _localtime_ict()
        print(f"[NTP] Synced (ICT): {t[0]}-{t[1]:02d}-{t[2]:02d} {t[3]:02d}:{t[4]:02d}:{t[5]:02d}")
        return True
    except Exception as e:
        print(f"[NTP] Failed: {e}")
        return False

def _get_current_weekday():
    return _localtime_ict()[6]

def _get_current_time_str():
    t = _localtime_ict()
    return f"{t[3]:02d}:{t[4]:02d}"

_DAY_NAME_MAP = {
    'monday': 0, 'tuesday': 1, 'wednesday': 2, 'thursday': 3,
    'friday': 4, 'saturday': 5, 'sunday': 6,
    'mon': 0, 'tue': 1, 'wed': 2, 'thu': 3, 'fri': 4, 'sat': 5, 'sun': 6,
    'thứ 2': 0, 'thứ 3': 1, 'thứ 4': 2, 'thứ 5': 3,
    'thứ 6': 4, 'thứ 7': 5, 'chủ nhật': 6, 'cn': 6,
}

def _parse_days_of_week(day_str):
    if not day_str:
        return []

    s = str(day_str).strip()

    if s.lower() in _DAY_NAME_MAP:
        return [_DAY_NAME_MAP[s.lower()]]

    result = []
    for ch in s:
        try:
            n = int(ch)
            if 1 <= n <= 7:
                result.append(n - 1)  # Flutter 1-7 → MP 0-6
        except ValueError:
            pass
    if not result:
        print(f"[Schedule] Cannot parse dayOfWeek: '{day_str}'")
    return result

def _print_schedule(schedule):
    if not schedule:
        print("[Schedule] No data.")
        return
    print(f"[Schedule] {len(schedule)} items:")
    for i, item in enumerate(schedule):
        print(f"  [{i+1}] day='{item.get('dayOfWeek')}' "
              f"time={item.get('time')} "
              f"power={item.get('powerStatus')} "
              f"active={item.get('active')}")

def _execute_schedule(schedule, relay_obj):
    if not schedule or relay_obj is None:
        if not schedule:
            print("[Schedule] No data, skipping check.")
        return

    current_day = _get_current_weekday()  # 0=Mon...6=Sun (ICT)
    current_time_str = _get_current_time_str()  # "HH:MM" (ICT)
    _DAY_NAMES = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun']
    print(f"[Schedule] Check: {_DAY_NAMES[current_day]} {current_time_str} | {len(schedule)} items")

    for item in schedule:
        if not item.get('active', False):
            continue

        mp_days = _parse_days_of_week(item.get('dayOfWeek'))
        if not mp_days or current_day not in mp_days:
            continue

        schedule_time = str(item.get('time', '')).strip()
        if not schedule_time:
            continue
        schedule_hhmm = ':'.join(schedule_time.split(':')[:2])

        print(f"[Schedule] Day match! Checking time: schedule={schedule_hhmm} now={current_time_str}")

        if schedule_hhmm != current_time_str:
            continue

        power_status = item.get('powerStatus')
        state = "on" if power_status else "off"
        control_relay(relay_obj, state)
        print(f"[Schedule] Executed: relay {state.upper()} "
              f"(id={item.get('id')}, {item.get('dayOfWeek')} {schedule_hhmm})")

def _try_post_power_log(mac_address, api_token, session_energy_wh):

    relay_on_t = get_relay_on_time()
    if relay_on_t is None:
        print("[PowerLog] relay_on_time not set. Skipping.")
        return

    relay_off_t = _localtime_ict()

    if not api_token:
        print("[PowerLog] No token cached. Retrying get_token()...")
        api_token = get_token()
        if not api_token:
            print("[PowerLog] Token fetch failed. Skipping API call.")
            return

    post_power_log(mac_address, api_token, relay_on_t, relay_off_t, session_energy_wh)

def _log_event(mqtt_client, level, message):
    payload = json.dumps({
        "timestamp": int(time.time()),
        "level": level,
        "message": message
    })
    print(f"[{level.upper()}] {message}")
    if mqtt_client:
        publish_message(mqtt_client, LOG_TOPIC, payload)

def main_loop():
    global _schedule_data

    print("=" * 40)
    print("IoT Smart Plug — Starting...")
    print("=" * 40)

    config = get_config()
    if not config:
        print("[FATAL] Config empty. Halting.")
        return

    mqtt_module.on_schedule_update = _on_schedule_update_callback

    init_hardware()
    main_relay = get_main_relay_obj()
    if main_relay is None:
        print("[WARN] Relay unavailable.")

    data_logger = DataLogger(
        filepath=config.get('data_logging', {}).get('filepath', '/data/telemetry.csv'),
        max_records=config.get('data_logging', {}).get('max_records', 1000)
    )

    mac_address = None
    for attempt in range(1, 4):
        print(f"[WiFi] Initial connect {attempt}/3...")
        mac_address = connect_wifi()
        if mac_address:
            break
        time.sleep(3)

    if not mac_address:
        print("[WiFi] All attempts failed. Starting captive portal for WiFi reconfiguration...")
        from captive_portal import run_captive_portal
        run_captive_portal()  # Blocking — resets device after saving new credentials
        return  # Không bao giờ tới đây

    for _ntp_attempt in range(5):
        if _sync_ntp():
            break
        print(f"[NTP] Retry {_ntp_attempt + 1}/5...")
        time.sleep(3)

    api_token = get_token()
    if api_token:
        fetched = fetch_json_data_schedule(mac_address, api_token)
        if fetched:
            _schedule_data = fetched
            _print_schedule(_schedule_data)
        else:
            print("[Schedule] API fetch failed. Trying flash cache...")
            _schedule_data = load_schedule_from_flash()
            _print_schedule(_schedule_data)
    else:
        print("[API] Token failed. Loading schedule from flash cache...")
        _schedule_data = load_schedule_from_flash()
        _print_schedule(_schedule_data)

    mqtt_client = connect_mqtt(force=True)
    if mqtt_client:
        print(f"[Main] MQTT connected. MAC={mac_address} | Listening for relay commands on 'smartplug/status'")
        print(f"[Main] Send: {{\"id\": \"{mac_address}\", \"value\": true/false}}")
        _log_event(mqtt_client, "info", f"Device started. MAC={mac_address} "
                   f"FW={get_current_version()}")
    else:
        print("[Main] MQTT connection FAILED.")

    last_telemetry_time = 0
    last_status_time = 0
    last_gc_time = time.time()
    last_schedule_check_time = time.time()
    last_schedule_refresh_time = time.time()
    boot_time = time.time()

    prev_relay_state = False  # False = OFF
    prev_session_energy = 0.0

    def _publish_relay_state(client, mac, state_str):
        if not client or not mac:
            return
        payload = json.dumps({"device_id": mac, "relay_status": state_str})
        try:
            publish_message(client, STATUS_TOPIC, payload, retain=True)
        except Exception:
            pass

    print("[Main] Entering main loop...")

    while True:
        try:
            current_time = time.time()

            if not is_wifi_connected():
                _log_event(None, "warning", "WiFi lost.")
                disconnect_mqtt()
                mqtt_client = None

                mac_address = reconnect_wifi_with_backoff(reason="watchdog")
                if not mac_address:
                    print("[WiFi] Reconnect failed. Reset in 5s.")
                    time.sleep(5)
                    machine.reset()
                    return

                _sync_ntp()
                reset_reconnect_cooldown()
                mqtt_client = connect_mqtt(force=True)
                if mqtt_client:
                    _log_event(mqtt_client, "info", "WiFi reconnected.")
                    data_logger.flush_to_mqtt(mqtt_client, TELEMETRY_TOPIC, publish_message)

                new_token = get_token()
                if new_token:
                    api_token = new_token

            if mqtt_client is None:
                mqtt_client = connect_mqtt()

            if mqtt_client:
                if not check_mqtt_messages(mqtt_client):
                    mqtt_client = None

            if main_relay:
                relay_is_on = main_relay.value() == 1

                if prev_relay_state and not relay_is_on:
                    session_e = get_session_energy()
                    print(f"[Main] Relay OFF. Session energy: {session_e:.4f} Wh")
                    _try_post_power_log(mac_address, api_token, session_e)
                    prev_session_energy = session_e
                    _publish_relay_state(mqtt_client, mac_address, "off")
                elif not prev_relay_state and relay_is_on:
                    _publish_relay_state(mqtt_client, mac_address, "on")

                prev_relay_state = relay_is_on

                if relay_is_on and not is_power_measurement_running():
                    start_power_measurement()
                elif not relay_is_on and is_power_measurement_running():
                    stop_power_measurement()

            if current_time - last_schedule_check_time >= SCHEDULE_CHECK_INTERVAL_SEC:
                _execute_schedule(_schedule_data, main_relay)
                last_schedule_check_time = current_time

            if current_time - last_schedule_refresh_time >= SCHEDULE_REFRESH_INTERVAL_SEC:
                print("[Schedule] Refreshing from API...")
                new_token = get_token()
                if new_token:
                    api_token = new_token
                    new_schedule = fetch_json_data_schedule(mac_address, api_token)
                    if new_schedule is not None:
                        _schedule_data = new_schedule
                        print(f"[Schedule] Refreshed: {len(_schedule_data)} items.")
                    else:
                        print("[Schedule] API refresh failed. Keeping current.")
                last_schedule_refresh_time = current_time

            if current_time - last_telemetry_time >= TELEMETRY_INTERVAL_SEC:
                rssi = get_rssi()
                voltage = 0.0
                current_a = 0.0
                power_w = 0.0
                try:
                    from smartplug import ac_measure as _ac
                    if _ac:
                        voltage = _ac.get_voltage()
                        current_a = _ac.get_current()
                        power_w = voltage * current_a
                except Exception:
                    pass

                relay_state = "on" if main_relay and main_relay.value() == 1 else "off"
                telemetry = {
                    "timestamp": int(current_time),
                    "voltage": round(voltage, 2),
                    "current": round(current_a, 4),
                    "power": round(power_w, 2),
                    "relay_status": relay_state,
                    "rssi": rssi,
                    "memory_free": gc.mem_free()
                }
                if mqtt_client:
                    publish_message(mqtt_client, TELEMETRY_TOPIC, json.dumps(telemetry))
                data_logger.append(int(current_time), voltage, current_a, power_w, rssi)
                last_telemetry_time = current_time

            if current_time - last_status_time >= STATUS_INTERVAL_SEC:
                relay_now = "ON" if main_relay and main_relay.value() == 1 else "OFF"
                print(f"[Status] WiFi={'OK' if is_wifi_connected() else 'LOST'} | "
                      f"MQTT={'OK' if mqtt_client else 'LOST'} | "
                      f"MAC={mac_address} | RSSI={get_rssi()} | Relay={relay_now}")
            if mqtt_client and current_time - last_status_time >= STATUS_INTERVAL_SEC:
                status = {
                    "device_id": mac_address,
                    "online": True,
                    "uptime": int(current_time - boot_time),
                    "memory_free": gc.mem_free(),
                    "rssi": get_rssi(),
                    "firmware_version": get_current_version(),
                    "total_energy_wh": round(get_total_energy(), 4),
                    "log_records": data_logger.get_record_count()
                }
                publish_message(mqtt_client, STATUS_TOPIC, json.dumps(status))
                last_status_time = current_time

            if config.get('ota', {}).get('enabled', False) and should_check_update():
                update_info = check_update()
                if update_info and update_info.get('available'):
                    _log_event(mqtt_client, "info",
                               f"OTA available: {update_info.get('version')}")
                    apply_update(update_info)

            if current_time - last_gc_time >= GC_INTERVAL_SEC:
                before = gc.mem_free()
                gc.collect()
                after = gc.mem_free()
                print(f"[GC] {before} -> {after} bytes (+{after - before})")
                last_gc_time = current_time

            time.sleep(0.2)

        except KeyboardInterrupt:
            print("[Main] KeyboardInterrupt.")
            break
        except Exception as e:
            import sys
            print(f"[Main] Unhandled: {e}")
            sys.print_exception(e)
            _log_event(None, "error", str(e))
            time.sleep(15)

try:
    main_loop()
finally:
    print("[Main] Cleanup...")
    stop_power_measurement()
    disconnect_mqtt()
    disconnect_wifi()
    print("[Main] Done.")
