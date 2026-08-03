import urequests as requests
import ujson as json
import uos
from config_loader import get_config

_SCHEDULE_CACHE_FILE = '/data/schedule.json'

def _get_api_config():
    config = get_config()
    return config.get('api_server', {})

def _ensure_data_dir():
    try:
        uos.stat('/data')
    except OSError:
        uos.mkdir('/data')

def _iso_datetime(t):
    return f"{t[0]:04d}-{t[1]:02d}-{t[2]:02d}T{t[3]:02d}:{t[4]:02d}:{t[5]:02d}"

def get_token():
    api_cfg = _get_api_config()
    base_url = api_cfg.get('base_url')
    endpoint = api_cfg.get('token_endpoint', '/login/Token')
    username = api_cfg.get('username')
    password = api_cfg.get('password')

    if not base_url or not username or not password:
        print("[API] get_token: missing base_url/username/password in config.")
        return None

    url = base_url + endpoint
    headers = {'accept': '*/*', 'Content-Type': 'application/json'}
    payload = {"id": username, "pass": password}
    res = None
    try:
        res = requests.post(url, headers=headers, data=json.dumps(payload))
        if res.status_code == 200:
            token = res.text.strip()
            if token:
                return token
            print("[API] get_token: empty response body.")
            return None
        print(f"[API] get_token HTTP {res.status_code}: {res.text[:120]}")
        return None
    except Exception as e:
        print(f"[API] get_token error: {e}")
        return None
    finally:
        if res:
            try:
                res.close()
            except Exception:
                pass

def fetch_json_data_schedule(mac_address, token):
    if not mac_address or not token:
        print("[API] fetch_schedule: missing mac_address or token.")
        return None

    api_cfg = _get_api_config()
    base_url = api_cfg.get('base_url')
    endpoint = api_cfg.get('schedule_endpoint', '/api/Schedules/device/')

    if not base_url:
        print("[API] fetch_schedule: base_url not configured.")
        return None

    url = base_url + endpoint + mac_address
    headers = {
        'accept': '*/*',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + token
    }
    res = None
    try:
        res = requests.get(url, headers=headers)
        if res.status_code == 200:
            data = res.json()
            save_schedule_to_flash(data)
            return data
        print(f'[API] fetch_schedule HTTP {res.status_code}')
        return None
    except Exception as e:
        print(f'[API] fetch_schedule error: {e}')
        return None
    finally:
        if res:
            try:
                res.close()
            except Exception:
                pass

def save_schedule_to_flash(schedule_data):
    if not schedule_data:
        return
    try:
        _ensure_data_dir()
        with open(_SCHEDULE_CACHE_FILE, 'w') as f:
            json.dump(schedule_data, f)
        print(f'[API] Schedule saved ({len(schedule_data)} items).')
    except Exception as e:
        print(f'[API] Failed to save schedule: {e}')

def load_schedule_from_flash():
    try:
        uos.stat(_SCHEDULE_CACHE_FILE)
        with open(_SCHEDULE_CACHE_FILE, 'r') as f:
            data = json.load(f)
        print(f'[API] Schedule loaded from flash ({len(data)} items).')
        return data
    except OSError:
        print('[API] No cached schedule on flash.')
        return None
    except Exception as e:
        print(f'[API] Failed to load schedule: {e}')
        return None

def post_power_log(mac_address, token, start_time_tuple, end_time_tuple, energy_wh):
    if not mac_address or not token:
        print('[API] post_power_log: missing mac or token.')
        return False
    api_cfg = _get_api_config()
    base_url = api_cfg.get('base_url')
    if not base_url:
        print('[API] post_power_log: base_url not configured.')
        return False
    import time as _time
    _ICT_OFFSET = 7 * 3600  # UTC+7
    url = base_url + '/api/UsagePowerLogs'
    headers = {
        'accept': '*/*',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + token
    }
    import uos as _uos, ubinascii as _ub
    def _gen_uuid4():
        b = bytearray(_uos.urandom(16))
        b[6] = (b[6] & 0x0f) | 0x40  # version 4
        b[8] = (b[8] & 0x3f) | 0x80  # variant
        h = _ub.hexlify(b).decode()
        return f"{h[0:8]}-{h[8:12]}-{h[12:16]}-{h[16:20]}-{h[20:32]}"

    payload = {
        'logId': _gen_uuid4(),
        'calculateDate': _iso_datetime(_time.localtime(_time.time() + _ICT_OFFSET)),
        'startDate': _iso_datetime(start_time_tuple),
        'endDate': _iso_datetime(end_time_tuple),
        'powerUsageWat': round(energy_wh, 6),
        'deviceId': mac_address
    }
    res = None
    try:
        res = requests.post(url, headers=headers, data=json.dumps(payload))
        if res.status_code in (200, 201):
            print(f'[API] Power log posted OK: {energy_wh:.4f} Wh')
            return True
        print(f'[API] post_power_log HTTP {res.status_code}: {res.text[:200]}')
        print(f'[API] payload was: {json.dumps(payload)[:200]}')
        return False
    except Exception as e:
        print(f'[API] post_power_log error: {e}')
        return False
    finally:
        if res:
            try:
                res.close()
            except Exception:
                pass
