import network
import time
import gc
from config_loader import get_config

_wlan_sta = None
_connected_mac = None

_reconnect_stats = {
    'success_count': 0,
    'fail_count': 0,
    'last_disconnect_reason': None
}

_BACKOFF_INTERVALS = [5, 15, 30, 60]  # seconds per retry level
_MAX_RETRIES = 3

def _get_wlan_sta():
    global _wlan_sta
    if _wlan_sta is None:
        _wlan_sta = network.WLAN(network.STA_IF)
    return _wlan_sta

def connect_wifi():
    global _connected_mac

    config = get_config()
    wifi_config = config.get('wifi', {})

    ssid = wifi_config.get('ssid')
    password = wifi_config.get('password')
    timeout = wifi_config.get('connect_timeout_sec', 30)

    if not ssid:
        print("[WiFi] Error: SSID not found in configuration.")
        return None

    wlan = _get_wlan_sta()

    if not wlan.active():
        print("[WiFi] Activating WLAN interface...")
        wlan.active(True)
        time.sleep(1)

    if wlan.isconnected():
        mac_bytes = wlan.config('mac')
        mac_str = ''.join(['%02x' % b for b in mac_bytes])
        _connected_mac = mac_str
        return _connected_mac

    print(f"[WiFi] Connecting to {ssid}...")
    try:
        wlan.connect(ssid, password)
    except OSError as e:
        print(f"[WiFi] OSError on connect: {e}. Resetting WiFi hardware...")
        try:
            wlan.active(False)
            time.sleep(2)
            wlan.active(True)
            time.sleep(1)
        except Exception:
            pass
        return None

    start_time = time.time()
    while not wlan.isconnected():
        if time.time() - start_time > timeout:
            print(f"[WiFi] Timeout after {timeout}s. Failed to connect to {ssid}.")
            return None
        print(f"[WiFi] Waiting... status={wlan.status()}")
        time.sleep(1)

    ip_config = wlan.ifconfig()
    mac_bytes = wlan.config('mac')
    mac_str = ''.join(['%02x' % b for b in mac_bytes])
    _connected_mac = mac_str

    print(f"[WiFi] Connected to {ssid} | IP: {ip_config[0]} | MAC: {_connected_mac}")
    gc.collect()
    return _connected_mac

def reconnect_wifi_with_backoff(reason=None):
    global _reconnect_stats

    _reconnect_stats['last_disconnect_reason'] = reason
    print(f"[WiFi] Reconnect triggered. Reason: {reason}")

    for attempt in range(1, _MAX_RETRIES + 1):
        wait_sec = _BACKOFF_INTERVALS[min(attempt - 1, len(_BACKOFF_INTERVALS) - 1)]
        print(f"[WiFi] Reconnect attempt {attempt}/{_MAX_RETRIES}, waiting {wait_sec}s...")
        time.sleep(wait_sec)

        wlan = _get_wlan_sta()
        if not wlan.active():
            wlan.active(True)
            time.sleep(1)

        mac = None
        try:
            mac = connect_wifi()
        except OSError as oe:
            print(f"[WiFi] OSError during connect: {oe}. Resetting WiFi hardware...")
            try:
                wlan.active(False)
                time.sleep(2)
                wlan.active(True)
                time.sleep(1)
            except Exception:
                pass

        if mac:
            _reconnect_stats['success_count'] += 1
            print(f"[WiFi] Reconnected successfully (attempt {attempt}). "
                  f"Stats: success={_reconnect_stats['success_count']}, "
                  f"fail={_reconnect_stats['fail_count']}")
            return mac

    _reconnect_stats['fail_count'] += 1
    print(f"[WiFi] Failed to reconnect after {_MAX_RETRIES} attempts. "
          f"Stats: success={_reconnect_stats['success_count']}, "
          f"fail={_reconnect_stats['fail_count']}")
    return None

def get_connected_mac():
    return _connected_mac

def is_wifi_connected():
    wlan = _get_wlan_sta()
    return wlan.isconnected()

def get_rssi():
    wlan = _get_wlan_sta()
    if wlan.isconnected():
        try:
            return wlan.status('rssi')
        except Exception:
            return 0
    return 0

def get_reconnect_stats():
    return dict(_reconnect_stats)

def disconnect_wifi():
    global _connected_mac, _wlan_sta
    wlan = _get_wlan_sta()
    if wlan.isconnected():
        wlan.disconnect()
    if wlan.active():
        wlan.active(False)
    _connected_mac = None
    _wlan_sta = None
    print("[WiFi] Disconnected and deactivated.")
