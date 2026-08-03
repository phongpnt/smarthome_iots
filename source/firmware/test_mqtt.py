import time
from machine import Pin
from config_loader import get_config
from umqtt.simple import MQTTClient
import network
import ujson

config = get_config()
wifi_cfg  = config.get('wifi', {})
mqtt_cfg  = config.get('mqtt', {})
relay_pin = config.get('device', {}).get('relay_pin', 23)

relay = Pin(relay_pin, Pin.OUT)
relay.value(0)

sta = network.WLAN(network.STA_IF)

ssid = wifi_cfg.get('ssid', '')
pwd  = wifi_cfg.get('password', '')

if sta.isconnected():
    print(f"WiFi already connected | IP={sta.ifconfig()[0]}")
else:
    print("Resetting WiFi driver...")
    sta.active(False)
    time.sleep(5)
    sta.active(True)
    time.sleep(5)
    print("Radio ready.")

    print(f"Connecting: '{ssid}'")
    sta.connect(ssid, pwd)

    for i in range(30):
        if sta.isconnected():
            break
        s = sta.status()
        print(f"  [{i+1}/30] status={s}")
        if s == 201:
            print("WRONG PASSWORD")
            raise SystemExit
        time.sleep(1)

if not sta.isconnected():
    print(f"WiFi FAILED status={sta.status()}")
    raise SystemExit

print(f"WiFi OK | IP={sta.ifconfig()[0]}")
mac = ''.join('%02x' % b for b in sta.config('mac'))
print(f"Device MAC: {mac}")

TOPIC = mqtt_cfg.get('subscribe_topic', 'smartplug/status').encode()

def on_message(topic, msg):
    topic_str = topic.decode()
    msg_str   = msg.decode()
    print(f"\n>>> MQTT received on '{topic_str}':")
    print(f"    raw  : {msg_str}")
    try:
        data = ujson.loads(msg_str)
        print(f"    parsed: {data}")
        value = data.get('value')
        target_id = data.get('id')
        if target_id is not None and target_id.lower().replace('-','').replace(':','') != mac:
            print(f"    SKIP: id={target_id} does not match mac={mac}")
            return
        if value is True or value == 1:
            relay.value(1)
            print(f"    RELAY → ON (pin={relay.value()})")
        elif value is False or value == 0:
            relay.value(0)
            print(f"    RELAY → OFF (pin={relay.value()})")
        else:
            print(f"    WARNING: 'value' not recognized: {value}")
    except Exception as e:
        print(f"    Parse error: {e}")

client = MQTTClient(
    b'test_' + mac.encode(),
    mqtt_cfg['server'],
    port=mqtt_cfg.get('port', 1883),
    user=mqtt_cfg.get('user'),
    password=mqtt_cfg.get('password'),
)
client.set_callback(on_message)
client.connect()
client.subscribe(TOPIC)
print(f"\nMQTT OK | subscribed: {TOPIC.decode()}")
print(f"Device MAC (dùng làm 'id'): {mac}")
print("Waiting for messages... (Ctrl+C to stop)\n")

while True:
    client.check_msg()
    time.sleep(0.2)
