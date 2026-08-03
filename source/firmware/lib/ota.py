import urequests as requests
import hashlib
import uos
import gc
import machine
import time
from config_loader import get_config

_VERSION_FILE = "/data/ota_version.json"
_OTA_CHECK_INTERVAL_SEC = 86400  # 24 giờ
_last_ota_check = 0

def _get_ota_config():
    config = get_config()
    return config.get('ota', {})

def get_current_version():
    try:
        import ujson
        with open(_VERSION_FILE, 'r') as f:
            data = ujson.load(f)
            return data.get('current', '0.0.0')
    except Exception:
        cfg = get_config()
        return cfg.get('firmware_version', '0.0.0')

def _save_version_info(current, available=None, last_check=None):
    import ujson
    try:
        try:
            uos.stat('/data')
        except OSError:
            uos.mkdir('/data')

        data = {
            'current': current,
            'available': available or current,
            'last_check': last_check or int(time.time())
        }
        with open(_VERSION_FILE, 'w') as f:
            ujson.dump(data, f)
    except Exception as e:
        print(f"[OTA] Cannot save version info: {e}")

def check_update():
    global _last_ota_check

    ota_cfg = _get_ota_config()
    check_url = ota_cfg.get('check_url')
    if not check_url:
        print("[OTA] check_url not configured.")
        return None

    current_version = get_current_version()
    print(f"[OTA] Checking for updates... Current: {current_version}")
    _last_ota_check = int(time.time())

    res = None
    try:
        res = requests.get(check_url, headers={'Accept': 'application/json'})
        if res.status_code != 200:
            print(f"[OTA] Check failed: HTTP {res.status_code}")
            return None

        data = res.json()
        latest_version = data.get('version', '0.0.0')
        download_url = data.get('url')
        sha256 = data.get('sha256')

        if _version_newer(latest_version, current_version):
            print(f"[OTA] New version available: {latest_version}")
            _save_version_info(current_version, latest_version, _last_ota_check)
            return {
                'available': True,
                'version': latest_version,
                'url': download_url,
                'sha256': sha256
            }
        else:
            print(f"[OTA] Already up-to-date: {current_version}")
            _save_version_info(current_version, latest_version, _last_ota_check)
            return {'available': False, 'version': current_version}

    except Exception as e:
        print(f"[OTA] check_update error: {e}")
        return None
    finally:
        if res:
            try:
                res.close()
            except Exception:
                pass

def _version_newer(v_new, v_current):
    try:
        new_parts = [int(x) for x in v_new.split('.')]
        cur_parts = [int(x) for x in v_current.split('.')]
        while len(new_parts) < 3:
            new_parts.append(0)
        while len(cur_parts) < 3:
            cur_parts.append(0)
        return new_parts > cur_parts
    except Exception:
        return False

def _download_firmware(url, dest_path):
    print(f"[OTA] Downloading firmware from {url}...")
    res = None
    try:
        res = requests.get(url)
        if res.status_code != 200:
            print(f"[OTA] Download failed: HTTP {res.status_code}")
            return False

        with open(dest_path, 'wb') as f:
            chunk_size = 512
            content = res.content  # MicroPython urequests trả về bytes
            total = len(content)
            written = 0
            while written < total:
                chunk = content[written:written + chunk_size]
                f.write(chunk)
                written += len(chunk)
                gc.collect()

        print(f"[OTA] Downloaded {written} bytes to {dest_path}")
        return True

    except Exception as e:
        print(f"[OTA] Download error: {e}")
        return False
    finally:
        if res:
            try:
                res.close()
            except Exception:
                pass

def _verify_sha256(filepath, expected_hash):
    if not expected_hash:
        print("[OTA] No SHA256 provided, skipping verification.")
        return True

    print("[OTA] Verifying SHA256...")
    try:
        h = hashlib.sha256()
        with open(filepath, 'rb') as f:
            while True:
                chunk = f.read(512)
                if not chunk:
                    break
                h.update(chunk)
                gc.collect()

        actual = h.digest()
        expected_bytes = bytes([int(expected_hash[i:i+2], 16)
                                 for i in range(0, len(expected_hash), 2)])
        if actual == expected_bytes:
            print("[OTA] SHA256 verified OK.")
            return True
        else:
            print(f"[OTA] SHA256 MISMATCH! Expected: {expected_hash}")
            return False
    except Exception as e:
        print(f"[OTA] SHA256 verify error: {e}")
        return False

def apply_update(update_info):
    url = update_info.get('url')
    new_version = update_info.get('version')
    sha256 = update_info.get('sha256')

    if not url:
        print("[OTA] No download URL provided.")
        return False

    temp_path = "/data/firmware_new.py"
    backup_path = "/data/firmware_backup.py"
    target_path = "main.py"

    if not _download_firmware(url, temp_path):
        print("[OTA] Download failed. Keeping current firmware.")
        _cleanup_temp(temp_path)
        return False

    if not _verify_sha256(temp_path, sha256):
        print("[OTA] Verification failed. Aborting update.")
        _cleanup_temp(temp_path)
        return False

    try:
        with open(target_path, 'rb') as src, open(backup_path, 'wb') as dst:
            while True:
                chunk = src.read(512)
                if not chunk:
                    break
                dst.write(chunk)
        print(f"[OTA] Current firmware backed up to {backup_path}")
    except Exception as e:
        print(f"[OTA] Backup failed: {e}")
        _cleanup_temp(temp_path)
        return False

    try:
        uos.rename(temp_path, target_path)
        print(f"[OTA] Firmware updated to version {new_version}.")
    except Exception as e:
        print(f"[OTA] Apply failed: {e}. Attempting rollback...")
        _rollback(backup_path, target_path)
        return False

    _save_version_info(new_version)
    print(f"[OTA] Rebooting to apply update...")
    time.sleep(2)
    machine.reset()
    return True  # Unreachable, thoả mãn return type

def _rollback(backup_path, target_path):
    try:
        uos.rename(backup_path, target_path)
        print("[OTA] Rollback successful. Current firmware restored.")
    except Exception as e:
        print(f"[OTA] CRITICAL: Rollback failed: {e}")

def _cleanup_temp(path):
    try:
        uos.remove(path)
    except Exception:
        pass

def should_check_update():
    return int(time.time()) - _last_ota_check >= _OTA_CHECK_INTERVAL_SEC
