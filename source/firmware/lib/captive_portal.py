import network
import socket
import time
import machine
import gc

AP_SSID = "M5Stack-Setup"
AP_PASSWORD = ""  # open network — phone triggers captive portal check faster
AP_IP = "192.168.4.1"
AP_SUBNET = "255.255.255.0"

_HTML_PAGE = """\
HTTP/1.0 200 OK\r\nContent-Type: text/html\r\n\r\n
<!DOCTYPE html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>WiFi Setup</title>
<style>
  body{font-family:sans-serif;max-width:360px;margin:40px auto;padding:0 16px;background:  # f5f5f5}
  h2{color:  # 333;text-align:center}
  label{display:block;margin:12px 0 4px;font-size:14px;color:  # 555}
  input{width:100%;box-sizing:border-box;padding:10px;border:1px solid  # ccc;border-radius:6px;font-size:16px}
  button{margin-top:20px;width:100%;padding:12px;background:
  button:active{background:  # 005fa3}
  .note{margin-top:16px;font-size:12px;color:  # 888;text-align:center}
</style></head>
<body>
<h2>&  # 128246; WiFi Setup</h2>
<form method="POST" action="/save">
  <label>SSID (tên WiFi)</label>
  <input name="ssid" type="text" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" required>
  <label>Password</label>
  <input name="password" type="password">
  <button type="submit">Lưu &amp; Khởi động lại</button>
</form>
<p class="note">Thiết bị sẽ tự khởi động lại sau khi lưu.</p>
</body></html>
HTTP/1.0 200 OK\r\nContent-Type: text/html\r\n\r\n
<!DOCTYPE html><html><head><meta charset="utf-8">
<title>Saved</title>
<style>body{font-family:sans-serif;max-width:360px;margin:80px auto;text-align:center;padding:0 16px}</style>
</head><body>
<h2>&  # 10003; Đã lưu!</h2>
<p>Thiết bị đang khởi động lại.<br>Vui lòng kết nối lại WiFi của bạn.</p>
</body></html>
HTTP/1.0 302 Found\r\nLocation: http://{ip}/\r\n\r\n
    sta = network.WLAN(network.STA_IF)
    if sta.active():
        sta.active(False)
    time.sleep(0.5)

    ap = network.WLAN(network.AP_IF)
    ap.active(True)
    if AP_PASSWORD:
        ap.config(essid=AP_SSID, password=AP_PASSWORD, authmode=network.AUTH_WPA_WPA2_PSK)
    else:
        ap.config(essid=AP_SSID, authmode=network.AUTH_OPEN)
    ap.ifconfig((AP_IP, AP_SUBNET, AP_IP, AP_IP))

    deadline = time.time() + 10
    while not ap.active() and time.time() < deadline:
        time.sleep(0.2)

    print(f"[Portal] AP up: SSID={AP_SSID} IP={AP_IP}")
    return ap

def _run_dns_server(stop_event):
    try:
        dns_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        dns_sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        dns_sock.bind(("0.0.0.0", 53))
        dns_sock.settimeout(0.05)
        print("[Portal] DNS server listening on :53")
    except Exception as e:
        print(f"[Portal] DNS bind failed: {e}")
        return

    ip_bytes = bytes(int(x) for x in AP_IP.split('.'))

    while not stop_event[0]:
        try:
            data, addr = dns_sock.recvfrom(512)
            if len(data) < 12:
                continue
            txid = data[:2]
            flags = b'\x81\x80'
            qdcount = data[4:6]
            response = txid + flags + qdcount + b'\x00\x01\x00\x00\x00\x00'  # header
            question = data[12:]
            response += question
            response += (
                b'\xc0\x0c'  # name pointer to question
                b'\x00\x01'  # type A
                b'\x00\x01'  # class IN
                b'\x00\x00\x00\x1e'  # TTL 30s
                b'\x00\x04'  # rdlength
                + ip_bytes
            )
            dns_sock.sendto(response, addr)
        except OSError:
            pass
        except Exception as e:
            print(f"[Portal] DNS error: {e}")

    dns_sock.close()
    print("[Portal] DNS server stopped.")

def _parse_post_body(body):
    result = {}
    try:
        for pair in body.split('&'):
            if '=' in pair:
                k, v = pair.split('=', 1)
                result[_urldecode(k)] = _urldecode(v)
    except Exception:
        pass
    return result

def _urldecode(s):
    out = []
    i = 0
    while i < len(s):
        c = s[i]
        if c == '+':
            out.append(' ')
            i += 1
        elif c == '%' and i + 2 < len(s):
            try:
                out.append(chr(int(s[i+1:i+3], 16)))
                i += 3
            except ValueError:
                out.append(c)
                i += 1
        else:
            out.append(c)
            i += 1
    return ''.join(out)

def _handle_http(conn, addr, saved_creds):
    try:
        conn.settimeout(3)
        request = b""
        while b"\r\n\r\n" not in request:
            chunk = conn.recv(512)
            if not chunk:
                break
            request += chunk

        request_str = request.decode('utf-8', 'ignore')
        first_line = request_str.split('\r\n')[0] if request_str else ""
        method = first_line.split(' ')[0] if first_line else ""
        path = first_line.split(' ')[1] if len(first_line.split(' ')) > 1 else "/"

        path = path.split('?')[0]

        print(f"[Portal] {method} {path} from {addr[0]}")

        if method == "POST" and path == "/save":
            body = ""
            cl_header = [l for l in request_str.split('\r\n') if l.lower().startswith('content-length:')]
            if cl_header:
                try:
                    content_length = int(cl_header[0].split(':')[1].strip())
                    body_start = request_str.find('\r\n\r\n')
                    if body_start >= 0:
                        body = request_str[body_start + 4:]
                    while len(body.encode('utf-8')) < content_length:
                        chunk = conn.recv(256)
                        if not chunk:
                            break
                        body += chunk.decode('utf-8', 'ignore')
                except Exception:
                    pass

            creds = _parse_post_body(body)
            ssid = creds.get('ssid', '').strip()
            password = creds.get('password', '')

            if ssid:
                saved_creds.append({'ssid': ssid, 'password': password})
                conn.send(_HTML_SAVED.encode())
            else:
                conn.send((_HTML_REDIRECT.format(ip=AP_IP)).encode())

        elif path in ('/', '/index.html', '/generate_204',
                      '/hotspot-detect.html', '/ncsi.txt',
                      '/connecttest.txt', '/redirect'):
            conn.send(_HTML_PAGE.encode())

        else:
            conn.send((_HTML_REDIRECT.format(ip=AP_IP)).encode())

    except Exception as e:
        print(f"[Portal] HTTP handler error: {e}")
    finally:
        conn.close()

def run_captive_portal():
    from config_loader import save_config, get_config

    ap = _start_ap()

    http_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    http_sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    http_sock.bind(("0.0.0.0", 80))
    http_sock.listen(3)
    http_sock.settimeout(0.1)
    print("[Portal] HTTP server listening on :80")

    stop_dns = [False]
    saved_creds = []

    try:
        dns_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        dns_sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        dns_sock.bind(("0.0.0.0", 53))
        dns_sock.settimeout(0.02)
        print("[Portal] DNS server listening on :53")
    except Exception as e:
        print(f"[Portal] DNS bind failed (non-fatal): {e}")
        dns_sock = None

    ip_bytes = bytes(int(x) for x in AP_IP.split('.'))

    print("[Portal] Waiting for WiFi credentials...")

    while not saved_creds:
        gc.collect()

        if dns_sock:
            try:
                data, addr = dns_sock.recvfrom(512)
                if len(data) >= 12:
                    txid = data[:2]
                    qdcount = data[4:6]
                    question = data[12:]
                    response = (txid + b'\x81\x80' + qdcount +
                                b'\x00\x01\x00\x00\x00\x00' + question +
                                b'\xc0\x0c\x00\x01\x00\x01\x00\x00\x00\x1e\x00\x04' +
                                ip_bytes)
                    dns_sock.sendto(response, addr)
            except OSError:
                pass

        try:
            conn, addr = http_sock.accept()
            _handle_http(conn, addr, saved_creds)
        except OSError:
            pass

    creds = saved_creds[0]
    print(f"[Portal] Got credentials: ssid={creds['ssid']}")

    if dns_sock:
        dns_sock.close()
    http_sock.close()

    import ujson as _ujson
    config = {}
    for _src in ('config_default.json', 'config.json'):
        try:
            with open(_src, 'r') as _f:
                _data = _ujson.load(_f)
            if len(_data) > 1:  # file hợp lệ, có đủ key
                config = _data
                print(f"[Portal] Config base loaded from {_src}")
                break
        except Exception:
            pass

    if 'wifi' not in config:
        config['wifi'] = {}
    config['wifi']['ssid'] = creds['ssid']
    config['wifi']['password'] = creds['password']
    save_config(config)

    print("[Portal] Config saved. Rebooting in 2s...")
    time.sleep(2)
    machine.reset()
