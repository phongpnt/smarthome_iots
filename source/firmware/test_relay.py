import time
from machine import Pin
from config_loader import get_config

print("=" * 40)
print("RELAY TEST")
print("=" * 40)

config = get_config()
relay_pin = config.get('device', {}).get('relay_pin', 23)
print(f"Relay pin from config: GPIO{relay_pin}")

relay = Pin(relay_pin, Pin.OUT)
relay.value(0)
print(f"Initial pin value: {relay.value()}")

for i in range(3):
    print(f"\n[{i+1}] Setting ON...")
    relay.value(1)
    print(f"  Pin value after ON: {relay.value()}")
    time.sleep(1)

    print(f"[{i+1}] Setting OFF...")
    relay.value(0)
    print(f"  Pin value after OFF: {relay.value()}")
    time.sleep(1)

print("\nRelay test done.")
print("Nếu không nghe tiếng click relay -> sai pin hoặc lỗi phần cứng.")
print("Pin value phải đổi 0->1->0 đúng như log trên.")
