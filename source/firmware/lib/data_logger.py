import gc
import uos

class DataLogger:

    HEADER = "timestamp,voltage,current,power,rssi\n"

    def __init__(self, filepath="/data/telemetry.csv", max_records=1000):
        self.filepath = filepath
        self.max_records = max_records
        self._record_count = 0
        self._ensure_dir()
        self._init_file()

    def _ensure_dir(self):
        dir_path = self.filepath.rsplit('/', 1)[0]
        if not dir_path:
            return
        try:
            uos.stat(dir_path)
        except OSError:
            try:
                uos.mkdir(dir_path)
                print(f"[Logger] Created directory: {dir_path}")
            except Exception as e:
                print(f"[Logger] Cannot create dir {dir_path}: {e}")

    def _init_file(self):
        try:
            uos.stat(self.filepath)
            self._record_count = self._count_records()
            print(f"[Logger] Existing log found: {self._record_count} records.")
        except OSError:
            try:
                with open(self.filepath, 'w') as f:
                    f.write(self.HEADER)
                self._record_count = 0
                print(f"[Logger] Created new log file: {self.filepath}")
            except Exception as e:
                print(f"[Logger] Cannot create log file: {e}")

    def _count_records(self):
        count = 0
        try:
            with open(self.filepath, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('timestamp'):
                        count += 1
        except Exception as e:
            print(f"[Logger] Error counting records: {e}")
        return count

    def _rotate(self):
        print(f"[Logger] Rotating log (>{self.max_records} records)...")
        tail_lines = []
        try:
            with open(self.filepath, 'r') as f:
                lines = f.readlines()
            data_lines = [l for l in lines if not l.startswith('timestamp')]
            tail_lines = data_lines[-100:] if len(data_lines) > 100 else data_lines
        except Exception as e:
            print(f"[Logger] Error reading for rotate: {e}")

        try:
            with open(self.filepath, 'w') as f:
                f.write(self.HEADER)
                for line in tail_lines:
                    f.write(line)
            self._record_count = len(tail_lines)
            print(f"[Logger] Rotated. Kept {self._record_count} records.")
        except Exception as e:
            print(f"[Logger] Rotate write error: {e}")

        gc.collect()

    def append(self, timestamp, voltage, current, power, rssi):
        if self._record_count >= self.max_records:
            self._rotate()

        line = f"{timestamp},{voltage:.2f},{current:.4f},{power:.2f},{rssi}\n"
        try:
            with open(self.filepath, 'a') as f:
                f.write(line)
            self._record_count += 1
            return True
        except Exception as e:
            print(f"[Logger] Append error: {e}")
            return False

    def get_record_count(self):
        return self._record_count

    def get_file_size(self):
        try:
            stat = uos.stat(self.filepath)
            return stat[6]
        except Exception:
            return 0

    def flush_to_mqtt(self, mqtt_client, topic, publish_fn, max_lines=50):
        sent = 0
        try:
            with open(self.filepath, 'r') as f:
                for line in f:
                    line = line.strip()
                    if not line or line.startswith('timestamp'):
                        continue
                    if sent >= max_lines:
                        break
                    publish_fn(mqtt_client, topic, line)
                    sent += 1
        except Exception as e:
            print(f"[Logger] flush_to_mqtt error: {e}")
        print(f"[Logger] Flushed {sent} records to MQTT.")
        return sent
