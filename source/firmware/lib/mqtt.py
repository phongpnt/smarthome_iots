import ujson as json
from umqtt.simple import MQTTClient
import ubinascii
import uos
import time
from config_loader import get_config
from smartplug import control_relay, get_main_relay_obj
import wifi_manage

_mqtt_client = None
_last_connection_attempt = 0
_RECONNECT_DELAY_SEC = 5

on_schedule_update = None

def _mqtt_callback(topic, msg):
    try:
        topic_str = topic.decode('utf-8', 'ignore')
        msg_str = msg.decode('utf-8', 'ignore')
        print(f"[MQTT] Received on '{topic_str}': {msg_str[:120]}")

        config = get_config()
        mqtt_config = config.get('mqtt', {})
        relay_topic = mqtt_config.get('subscribe_topic', 'smartplug/status')
        schedule_topic = mqtt_config.get('schedule_topic', 'smartplug/schedule')

        if topic_str == relay_topic:
            _handle_relay_command(msg_str)

        elif topic_str == schedule_topic:
            _handle_schedule_update(msg_str)

    except Exception as e:
        print(f"[MQTT] Callback error: {e}")

def _normalize_id(s):
    return str(s).lower().replace('-', '').replace(':', '')

def _handle_relay_command(msg_str):
    my_mac = wifi_manage.get_connected_mac()
    print(f"[MQTT] Device MAC: {my_mac}")
    try:
        data = json.loads(msg_str)
        target_id = data.get('id')
        value = data.get('value')

        if target_id is not None:
            if _normalize_id(target_id) != _normalize_id(my_mac or ''):
                print(f"[MQTT] Ignored: id={target_id} != mac={my_mac}")
                return

        if value is None:
            print("[MQTT] Warning: 'value' missing in relay command.")
            return

        relay_obj = get_main_relay_obj()
        if relay_obj is not None:
            state = "on" if value else "off"
            control_relay(relay_obj, state)
            print(f"[MQTT] Relay → {state.upper()} (via MQTT command)")
        else:
            print("[MQTT] Relay object unavailable.")

    except ValueError:
        print(f"[MQTT] Invalid JSON in relay command: {msg_str}")
    except Exception as e:
        print(f"[MQTT] Relay command error: {e}")

def _handle_schedule_update(msg_str):
    global on_schedule_update
    try:
        data = json.loads(msg_str)
        if isinstance(data, list):
            schedule_list = data
        elif isinstance(data, dict):
            schedule_list = [data]
        else:
            print("[MQTT] Unexpected schedule data format.")
            return

        print(f"[MQTT] Schedule update received: {len(schedule_list)} items.")

        from access_apiserver import save_schedule_to_flash
        save_schedule_to_flash(schedule_list)

        if on_schedule_update is not None:
            on_schedule_update(schedule_list)
        else:
            print("[MQTT] Warning: on_schedule_update hook not set.")

    except ValueError:
        print(f"[MQTT] Invalid JSON in schedule update: {msg_str}")
    except Exception as e:
        print(f"[MQTT] Schedule update error: {e}")

def _generate_client_id():
    my_mac = wifi_manage.get_connected_mac()
    if my_mac:
        return b"smartplug_" + my_mac.encode()
    random_bytes = uos.urandom(4)
    print("[MQTT] Warning: Using random client ID.")
    return b"smartplug_rand_" + ubinascii.hexlify(random_bytes)

def connect_mqtt(force=False):
    global _mqtt_client, _last_connection_attempt

    if _mqtt_client is not None:
        return _mqtt_client

    current_time = time.time()
    if not force and (current_time - _last_connection_attempt < _RECONNECT_DELAY_SEC):
        return None

    _last_connection_attempt = current_time

    config = get_config()
    mqtt_config = config.get('mqtt', {})

    server = mqtt_config.get('server')
    port = mqtt_config.get('port', 1883)
    user = mqtt_config.get('user')
    password = mqtt_config.get('password')
    keepalive = mqtt_config.get('keepalive', 120)

    if not server:
        print("[MQTT] Server not configured.")
        return None

    client_id = _generate_client_id()
    print(f"[MQTT] Connecting to {server}:{port} (ID: {client_id.decode()})...")

    try:
        client = MQTTClient(client_id, server, port=port,
                            user=user, password=password, keepalive=keepalive)
        client.set_callback(_mqtt_callback)
        client.connect()
        print("[MQTT] Connected.")

        relay_topic = mqtt_config.get('subscribe_topic', 'smartplug/status')
        schedule_topic = mqtt_config.get('schedule_topic', 'smartplug/schedule')
        for t in [relay_topic, schedule_topic]:
            if t:
                client.subscribe(t.encode('utf-8'))
                print(f"[MQTT] Subscribed: {t}")

        _mqtt_client = client
        return _mqtt_client

    except OSError as e:
        print(f"[MQTT] OSError: {e}")
    except Exception as e:
        print(f"[MQTT] Error: {e}")

    _mqtt_client = None
    return None

def publish_message(client, topic, message, retain=False):
    global _mqtt_client
    if not client or not topic or message is None:
        return False
    try:
        client.publish(topic.encode('utf-8'), str(message).encode('utf-8'), retain=retain)
        return True
    except Exception as e:
        print(f"[MQTT] Publish failed on '{topic}': {e}")
        _mqtt_client = None
        return False

def check_mqtt_messages(client):
    global _mqtt_client
    if not client:
        return False
    try:
        client.check_msg()
        return True
    except OSError as e:
        print(f'[MQTT] check_msg OSError: {e}')
        _mqtt_client = None
        return False
    except Exception as e:
        print(f'[MQTT] check_msg error: {e}')
        _mqtt_client = None
        return False

def disconnect_mqtt():
    global _mqtt_client
    if _mqtt_client:
        try:
            _mqtt_client.disconnect()
            print('[MQTT] Disconnected.')
        except Exception as e:
            print(f'[MQTT] Disconnect error: {e}')
        finally:
            _mqtt_client = None

def reset_reconnect_cooldown():
    global _last_connection_attempt
    _last_connection_attempt = 0
