#!/usr/bin/env python3
"""Edit only the standard lock/DPMS listeners in the user's hypridle config."""
import hashlib
import json
import math
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import tempfile
import time

BLOCK = re.compile(r"(?m)^listener\s*\{\s*\n.*?^\s*\}[ \t]*\n?", re.S)
META = re.compile(r"(?m)^# end4-idle-settings: (.+)\n?")


def kind(block):
    if re.search(r"(?m)^\s*on-timeout\s*=\s*loginctl lock-session\s*$", block):
        return "lock"
    if re.search(r"(?m)^\s*on-timeout\s*=.*\bdpms\b.*action\s*=\s*\"disable\"", block):
        return "display"
    return None


def read_state(text):
    state = {"lockEnabled": False, "lockMinutes": 5, "displayEnabled": False, "displayMinutes": 10}
    meta = META.search(text)
    if meta:
        saved = json.loads(meta.group(1))
        for field in ("lockMinutes", "displayMinutes"):
            state[field] = max(1, min(1440, int(saved.get(field, state[field]))))
    seen = set()
    for match in BLOCK.finditer(text):
        name = kind(match.group())
        if not name:
            continue
        if name in seen:
            raise ValueError("Multiple managed listeners; resolve duplicates before editing")
        seen.add(name)
        timeout = re.search(r"(?m)^\s*timeout\s*=\s*(\d+)", match.group())
        if not timeout:
            raise ValueError("Missing listener timeout")
        state[name + "Enabled"] = True
        state[name + "Minutes"] = max(1, math.ceil(int(timeout.group(1)) / 60))
    state["revision"] = hashlib.sha256(text.encode()).hexdigest()
    return state


def render(text, state):
    # Preserve general settings and all unrelated listeners verbatim.
    text = META.sub("", text)
    text = BLOCK.sub(lambda m: "" if kind(m.group()) else m.group(), text).rstrip() + "\n"
    metadata = {key: state[key] for key in ("lockMinutes", "displayMinutes")}
    text += "\n# end4-idle-settings: " + json.dumps(metadata) + "\n"
    if state["lockEnabled"]:
        text += "\nlistener {\n    timeout = %d\n    on-timeout = loginctl lock-session\n}\n" % (state["lockMinutes"] * 60)
    if state["displayEnabled"]:
        text += "\nlistener {\n    timeout = %d\n    on-timeout = hyprctl dispatch 'hl.dsp.dpms({ action = \"disable\" })'\n    on-resume = hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'\n}\n" % (state["displayMinutes"] * 60)
    return text


def atomic_write(path, text):
    fd, temporary = tempfile.mkstemp(prefix=".idle-settings-", dir=path.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            stream.write(text)
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temporary, path.stat().st_mode & 0o777)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def restart_idle():
    active = subprocess.run(["systemctl", "--user", "is-active", "--quiet", "hypridle.service"], check=False)
    if active.returncode == 0:
        subprocess.run(["systemctl", "--user", "restart", "hypridle.service"], check=True)
        return
    # This installation starts hypridle directly from Hyprland's execs.lua.
    processes = subprocess.run(["pgrep", "-u", str(os.getuid()), "-x", "hypridle"], capture_output=True, text=True)
    env = os.environ.copy()
    for value in processes.stdout.split():
        pid = int(value)
        proc = Path("/proc") / value
        args = (proc / "cmdline").read_bytes().split(b"\0")
        if b"-c" in args or b"--config" in args:
            raise ValueError("Custom hypridle process requires manual reload")
        for entry in (proc / "environ").read_bytes().split(b"\0"):
            key, _, val = entry.partition(b"=")
            if key.decode() in ("WAYLAND_DISPLAY", "HYPRLAND_INSTANCE_SIGNATURE", "XDG_RUNTIME_DIR", "DBUS_SESSION_BUS_ADDRESS"):
                env[key.decode()] = val.decode()
        os.kill(pid, signal.SIGTERM)
    for _ in range(40):
        if subprocess.run(["pgrep", "-u", str(os.getuid()), "-x", "hypridle"], stdout=subprocess.DEVNULL).returncode != 0:
            break
        time.sleep(0.05)
    else:
        raise RuntimeError("hypridle did not stop")
    log = Path.home() / ".local/state/illogical-impulse/hypridle.log"
    log.parent.mkdir(parents=True, exist_ok=True)
    with log.open("a") as stream:
        process = subprocess.Popen(["hypridle"], env=env, stdin=subprocess.DEVNULL, stdout=stream, stderr=stream, start_new_session=True)
    time.sleep(0.3)
    if process.poll() is not None:
        raise RuntimeError("hypridle could not start")


def main():
    path = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))) / "hypr/hypridle.conf"
    # Honor a symlinked dotfile without replacing the symlink itself.
    path = path.resolve(strict=True)
    original = path.read_text()
    state = read_state(original)
    if sys.argv[1:] == ["status"]:
        return state
    if len(sys.argv) != 7 or sys.argv[1] != "apply":
        raise ValueError("Invalid arguments")
    if sys.argv[2] != state["revision"]:
        raise ValueError("Configuration changed; refresh before applying")
    if sys.argv[3] not in ("0", "1") or sys.argv[5] not in ("0", "1"):
        raise ValueError("Invalid toggle")
    state.update(lockEnabled=sys.argv[3] == "1", lockMinutes=int(sys.argv[4]),
                 displayEnabled=sys.argv[5] == "1", displayMinutes=int(sys.argv[6]))
    if not all(1 <= state[key] <= 1440 for key in ("lockMinutes", "displayMinutes")):
        raise ValueError("Timeout must be between 1 and 1440 minutes")
    updated = render(original, state)
    backup = path.with_name(path.name + ".before-end4-idle-settings")
    if not backup.exists():
        backup.write_text(original)
        backup.chmod(0o600)
    atomic_write(path, updated)
    try:
        restart_idle()
    except Exception:
        atomic_write(path, original)
        restart_idle()
        raise
    return read_state(updated)


if __name__ == "__main__":
    try:
        print(json.dumps({"ok": True, **main()}))
    except Exception as error:
        print(json.dumps({"ok": False, "error": str(error)}))
        sys.exit(1)
