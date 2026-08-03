import ujson
import uos

CONFIG_FILE = 'config.json'
_config = None

def get_config():
    global _config
    if _config is None:
        try:
            uos.stat(CONFIG_FILE)
            with open(CONFIG_FILE, 'r') as f:
                _config = ujson.load(f)
            print("[Config] Loaded.")
        except OSError:
            print(f"[Config] '{CONFIG_FILE}' not found.")
            _config = {}
        except ValueError:
            print(f"[Config] JSON decode error.")
            _config = {}
        except Exception as e:
            print(f"[Config] Error: {e}")
            _config = {}
    return _config

def reload_config():
    global _config
    _config = None

def save_config(config):
    global _config
    try:
        with open(CONFIG_FILE, 'w') as f:
            ujson.dump(config, f)
        _config = config
        print("[Config] Saved.")
        return True
    except Exception as e:
        print(f"[Config] Save error: {e}")
        return False
