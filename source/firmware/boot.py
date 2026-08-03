import gc
import sys

gc.collect()
print("[Boot] Starting...")

def _has_wifi_config():
    try:
        from config_loader import get_config
        cfg = get_config()
        ssid = cfg.get('wifi', {}).get('ssid', '')
        return bool(ssid and ssid.strip())
    except Exception:
        return False

try:
    if _has_wifi_config():
        print("[Boot] WiFi config found. Starting main...")
        import main
    else:
        print("[Boot] No WiFi config. Starting captive portal for provisioning...")
        from captive_portal import run_captive_portal
        run_captive_portal()
except Exception as e:
    print("[Boot] Fatal error:")
    sys.print_exception(e)
    print("[Boot] Halted. Reset device manually.")
