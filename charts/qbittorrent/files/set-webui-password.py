# https://github.com/qbittorrent/qBittorrent/blob/master/src/base/utils/password.cpp
import hashlib, os, base64, secrets, re
from pathlib import Path

password = os.environ['WEBUI_PASSWORD']
salt = secrets.token_bytes(16)  # 4x uint32
key = hashlib.pbkdf2_hmac('sha512', password.encode(), salt, 100000, dklen=64)
hash_value = '@ByteArray(' + base64.b64encode(salt).decode() + ':' + base64.b64encode(key).decode() + ')'
line = 'WebUI\\Password_PBKDF2="' + hash_value + '"'

config_dir = Path('/config/qBittorrent')
config_dir.mkdir(parents=True, exist_ok=True)
config_path = config_dir / 'qBittorrent.conf'

if config_path.exists():
    text = config_path.read_text()
    if 'Password_PBKDF2' in text:
        text = re.sub(r'WebUI.Password_PBKDF2=.*', lambda _: line, text)
    elif '[Preferences]' in text:
        text = text.replace('[Preferences]', '[Preferences]\n' + line, 1)
    else:
        text += '\n[Preferences]\n' + line + '\n'
else:
    text = '[Preferences]\n' + line + '\n'

config_path.write_text(text)
print('WebUI password set')
