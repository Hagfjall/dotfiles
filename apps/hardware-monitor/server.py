#!/usr/bin/env python3
"""Hardware monitoring web server — serves a live dashboard on port 7070."""

import json
import subprocess
import re
import sys
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse

# ── Data collectors ──────────────────────────────────────────────────────────

def get_cpu_usage():
    try:
        result = subprocess.run(
            ["top", "-bn1"], capture_output=True, text=True, timeout=5
        )
        for line in result.stdout.split("\n"):
            if "%Cpu" in line:
                m = re.search(r"(\d+\.?\d*)\s+id", line)
                if m:
                    return round(100 - float(m.group(1)), 1)
    except Exception:
        pass
    return 0.0


def get_cpu_temp():
    """Try lm-sensors first, then /sys/class/thermal fallback."""
    try:
        result = subprocess.run(
            ["sensors", "-j"], capture_output=True, text=True, timeout=5
        )
        if result.returncode == 0:
            data = json.loads(result.stdout)
            for chip_values in data.values():
                for key, val in chip_values.items():
                    if any(k in key for k in ("Core", "Tdie", "Package", "Tccd", "k10temp")):
                        for metric, temp in val.items():
                            if "input" in metric and isinstance(temp, (int, float)):
                                return round(float(temp), 1)
    except Exception:
        pass
    # Fallback: read first thermal zone
    try:
        with open("/sys/class/thermal/thermal_zone0/temp") as f:
            return round(int(f.read().strip()) / 1000, 1)
    except Exception:
        pass
    return None


def get_memory():
    try:
        with open("/proc/meminfo") as f:
            meminfo = f.read()
        total = int(re.search(r"MemTotal:\s+(\d+)", meminfo).group(1))
        available = int(re.search(r"MemAvailable:\s+(\d+)", meminfo).group(1))
        used = total - available
        return {
            "total_gb": round(total / 1024 / 1024, 2),
            "used_gb": round(used / 1024 / 1024, 2),
            "available_gb": round(available / 1024 / 1024, 2),
            "percent": round(used / total * 100, 1),
        }
    except Exception:
        return {"total_gb": 0, "used_gb": 0, "available_gb": 0, "percent": 0}


def get_gpu_stats():
    try:
        result = subprocess.run(
            [
                "nvidia-smi",
                "--query-gpu=name,utilization.gpu,utilization.memory,"
                "memory.used,memory.total,temperature.gpu",
                "--format=csv,noheader,nounits",
            ],
            capture_output=True,
            text=True,
            timeout=5,
        )
        if result.returncode == 0 and result.stdout.strip():
            gpus = []
            for line in result.stdout.strip().split("\n"):
                parts = [p.strip() for p in line.split(",")]
                if len(parts) >= 6:
                    mem_used = round(float(parts[3]) / 1024, 2)
                    mem_total = round(float(parts[4]) / 1024, 2)
                    gpus.append(
                        {
                            "name": parts[0],
                            "gpu_util": float(parts[1]),
                            "mem_util": float(parts[2]),
                            "mem_used_gb": mem_used,
                            "mem_total_gb": mem_total,
                            "mem_percent": round(mem_used / mem_total * 100, 1) if mem_total else 0,
                            "temp": float(parts[5]),
                        }
                    )
            return gpus if gpus else None
    except (FileNotFoundError, Exception):
        pass
    return None


def get_disks():
    try:
        result = subprocess.run(
            [
                "df", "-B1",
                "--output=target,size,used,avail,pcent",
                "-x", "tmpfs", "-x", "devtmpfs", "-x", "squashfs", "-x", "efivarfs",
            ],
            capture_output=True,
            text=True,
            timeout=5,
        )
        disks = []
        for line in result.stdout.strip().split("\n")[1:]:
            parts = line.split()
            if len(parts) >= 5:
                size_b = int(parts[1])
                used_b = int(parts[2])
                avail_b = int(parts[3])
                pct = int(parts[4].replace("%", ""))
                def fmt(b):
                    for unit in ("B", "KB", "MB", "GB", "TB"):
                        if b < 1024:
                            return f"{b:.1f} {unit}"
                        b /= 1024
                    return f"{b:.1f} PB"
                disks.append(
                    {
                        "mount": parts[0],
                        "size": fmt(size_b),
                        "used": fmt(used_b),
                        "avail": fmt(avail_b),
                        "percent": pct,
                    }
                )
        return disks
    except Exception:
        return []


def get_stats():
    return {
        "cpu": {"usage": get_cpu_usage(), "temp": get_cpu_temp()},
        "memory": get_memory(),
        "gpus": get_gpu_stats(),
        "disks": get_disks(),
    }


# ── HTML dashboard ────────────────────────────────────────────────────────────

HTML = r"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Hardware Monitor</title>
<style>
  :root {
    --bg: #0d0d0f;
    --card: #141418;
    --border: #222228;
    --text: #e0e0e8;
    --muted: #666680;
    --accent: #4f8cff;
    --green: #3ecf8e;
    --yellow: #f5c842;
    --red: #f5534f;
    --purple: #b17bff;
    --gpu-color: #3ecf8e;
  }

  * { box-sizing: border-box; margin: 0; padding: 0; }

  body {
    background: var(--bg);
    color: var(--text);
    font-family: 'Segoe UI', system-ui, sans-serif;
    min-height: 100vh;
    padding: 24px;
  }

  header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 28px;
  }

  h1 {
    font-size: 1.4rem;
    font-weight: 600;
    letter-spacing: 0.02em;
    color: var(--text);
  }

  #updated {
    font-size: 0.78rem;
    color: var(--muted);
  }

  .dot {
    display: inline-block;
    width: 8px; height: 8px;
    border-radius: 50%;
    background: var(--green);
    margin-right: 8px;
    animation: pulse 2s infinite;
  }

  @keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.4; }
  }

  .grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(340px, 1fr));
    gap: 20px;
  }

  .card {
    background: var(--card);
    border: 1px solid var(--border);
    border-radius: 14px;
    padding: 24px;
  }

  .card-title {
    font-size: 0.72rem;
    font-weight: 600;
    letter-spacing: 0.1em;
    text-transform: uppercase;
    color: var(--muted);
    margin-bottom: 20px;
  }

  /* Gauge */
  .gauge-row {
    display: flex;
    align-items: center;
    gap: 28px;
  }

  .gauge-wrap {
    position: relative;
    width: 110px; height: 110px;
    flex-shrink: 0;
  }

  .gauge-svg {
    width: 110px; height: 110px;
    transform: rotate(-90deg);
  }

  .gauge-bg { fill: none; stroke: var(--border); stroke-width: 10; }
  .gauge-fill {
    fill: none;
    stroke-width: 10;
    stroke-linecap: round;
    transition: stroke-dashoffset 0.5s ease, stroke 0.5s ease;
  }

  .gauge-label {
    position: absolute;
    top: 50%; left: 50%;
    transform: translate(-50%, -50%);
    text-align: center;
  }

  .gauge-pct {
    font-size: 1.35rem;
    font-weight: 700;
    line-height: 1;
    display: block;
  }

  .gauge-sub {
    font-size: 0.65rem;
    color: var(--muted);
    display: block;
    margin-top: 2px;
  }

  .stats-list {
    display: flex;
    flex-direction: column;
    gap: 10px;
    flex: 1;
  }

  .stat-row {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .stat-key { font-size: 0.8rem; color: var(--muted); }
  .stat-val { font-size: 0.85rem; font-weight: 600; }

  /* Temp color */
  .temp-ok    { color: var(--green); }
  .temp-warm  { color: var(--yellow); }
  .temp-hot   { color: var(--red); }

  /* Bar */
  .bar-list { display: flex; flex-direction: column; gap: 14px; }

  .bar-item-header {
    display: flex;
    justify-content: space-between;
    margin-bottom: 6px;
    font-size: 0.8rem;
  }

  .bar-item-header .mount { color: var(--text); }
  .bar-item-header .bar-pct { color: var(--muted); }

  .bar-track {
    height: 7px;
    background: var(--border);
    border-radius: 4px;
    overflow: hidden;
  }

  .bar-fill {
    height: 100%;
    border-radius: 4px;
    transition: width 0.5s ease, background 0.5s ease;
  }

  .bar-meta {
    display: flex;
    justify-content: space-between;
    font-size: 0.72rem;
    color: var(--muted);
    margin-top: 4px;
  }

  /* GPU section title */
  .gpu-name {
    font-size: 0.82rem;
    color: var(--accent);
    margin-bottom: 18px;
    margin-top: -4px;
  }

  /* Offline */
  .offline-msg {
    color: var(--muted);
    font-size: 0.85rem;
    font-style: italic;
  }

  .card.gpu-card { border-color: #1a2a1a; }
</style>
</head>
<body>

<header>
  <h1><span class="dot"></span>Hardware Monitor</h1>
  <span id="updated">–</span>
</header>

<div class="grid" id="grid">
  <!-- CPU -->
  <div class="card" id="card-cpu">
    <div class="card-title">CPU</div>
    <div class="gauge-row">
      <div class="gauge-wrap">
        <svg class="gauge-svg" viewBox="0 0 110 110">
          <circle class="gauge-bg" cx="55" cy="55" r="45"/>
          <circle class="gauge-fill" id="cpu-gauge" cx="55" cy="55" r="45"
            stroke="var(--accent)"
            stroke-dasharray="282.74"
            stroke-dashoffset="282.74"/>
        </svg>
        <div class="gauge-label">
          <span class="gauge-pct" id="cpu-pct" style="color:var(--accent)">–</span>
          <span class="gauge-sub">usage</span>
        </div>
      </div>
      <div class="stats-list">
        <div class="stat-row">
          <span class="stat-key">Temperature</span>
          <span class="stat-val" id="cpu-temp">–</span>
        </div>
      </div>
    </div>
  </div>

  <!-- Memory -->
  <div class="card" id="card-mem">
    <div class="card-title">Memory</div>
    <div class="gauge-row">
      <div class="gauge-wrap">
        <svg class="gauge-svg" viewBox="0 0 110 110">
          <circle class="gauge-bg" cx="55" cy="55" r="45"/>
          <circle class="gauge-fill" id="mem-gauge" cx="55" cy="55" r="45"
            stroke="var(--purple)"
            stroke-dasharray="282.74"
            stroke-dashoffset="282.74"/>
        </svg>
        <div class="gauge-label">
          <span class="gauge-pct" id="mem-pct" style="color:var(--purple)">–</span>
          <span class="gauge-sub">used</span>
        </div>
      </div>
      <div class="stats-list">
        <div class="stat-row">
          <span class="stat-key">Used</span>
          <span class="stat-val" id="mem-used">–</span>
        </div>
        <div class="stat-row">
          <span class="stat-key">Available</span>
          <span class="stat-val" id="mem-avail">–</span>
        </div>
        <div class="stat-row">
          <span class="stat-key">Total</span>
          <span class="stat-val" id="mem-total">–</span>
        </div>
      </div>
    </div>
  </div>

  <!-- GPU placeholder -->
  <div class="card gpu-card" id="card-gpu">
    <div class="card-title">GPU</div>
    <div id="gpu-content"><span class="offline-msg">Waiting for data…</span></div>
  </div>

  <!-- Disks -->
  <div class="card" id="card-disk">
    <div class="card-title">Disk Storage</div>
    <div class="bar-list" id="disk-list">
      <span class="offline-msg">Waiting for data…</span>
    </div>
  </div>
</div>

<script>
const CIRC = 282.74;

function barColor(pct) {
  if (pct < 60) return 'var(--green)';
  if (pct < 80) return 'var(--yellow)';
  return 'var(--red)';
}

function tempColor(t) {
  if (t === null || t === undefined) return '';
  if (t < 60) return 'temp-ok';
  if (t < 80) return 'temp-warm';
  return 'temp-hot';
}

function setGauge(id, pct) {
  const el = document.getElementById(id);
  if (!el) return;
  el.style.strokeDashoffset = CIRC - (pct / 100) * CIRC;
}

function update(data) {
  // CPU
  const cpu = data.cpu;
  document.getElementById('cpu-pct').textContent = cpu.usage + '%';
  setGauge('cpu-gauge', cpu.usage);

  const tempEl = document.getElementById('cpu-temp');
  if (cpu.temp !== null && cpu.temp !== undefined) {
    tempEl.textContent = cpu.temp + ' °C';
    tempEl.className = 'stat-val ' + tempColor(cpu.temp);
  } else {
    tempEl.textContent = 'N/A';
    tempEl.className = 'stat-val';
  }

  // Memory
  const mem = data.memory;
  document.getElementById('mem-pct').textContent = mem.percent + '%';
  setGauge('mem-gauge', mem.percent);
  document.getElementById('mem-used').textContent = mem.used_gb + ' GB';
  document.getElementById('mem-avail').textContent = mem.available_gb + ' GB';
  document.getElementById('mem-total').textContent = mem.total_gb + ' GB';

  // GPU
  const gpuContent = document.getElementById('gpu-content');
  if (data.gpus && data.gpus.length > 0) {
    const g = data.gpus[0];
    gpuContent.innerHTML = `
      <div class="gpu-name">${g.name}</div>
      <div class="gauge-row">
        <div class="gauge-wrap">
          <svg class="gauge-svg" viewBox="0 0 110 110">
            <circle class="gauge-bg" cx="55" cy="55" r="45"/>
            <circle class="gauge-fill" id="gpu-util-gauge" cx="55" cy="55" r="45"
              stroke="var(--gpu-color)"
              stroke-dasharray="${CIRC}"
              stroke-dashoffset="${CIRC - (g.gpu_util / 100) * CIRC}"/>
          </svg>
          <div class="gauge-label">
            <span class="gauge-pct" style="color:var(--gpu-color)">${g.gpu_util}%</span>
            <span class="gauge-sub">gpu</span>
          </div>
        </div>
        <div class="stats-list">
          <div class="stat-row">
            <span class="stat-key">VRAM Used</span>
            <span class="stat-val">${g.mem_used_gb} / ${g.mem_total_gb} GB</span>
          </div>
          <div class="stat-row">
            <span class="stat-key">VRAM %</span>
            <span class="stat-val">${g.mem_percent}%</span>
          </div>
          <div class="stat-row">
            <span class="stat-key">Temperature</span>
            <span class="stat-val ${tempColor(g.temp)}">${g.temp} °C</span>
          </div>
        </div>
      </div>`;
  } else {
    gpuContent.innerHTML = '<span class="offline-msg">No NVIDIA GPU detected</span>';
  }

  // Disks
  const diskList = document.getElementById('disk-list');
  if (data.disks && data.disks.length > 0) {
    diskList.innerHTML = data.disks.map(d => `
      <div class="bar-item">
        <div class="bar-item-header">
          <span class="mount">${d.mount}</span>
          <span class="bar-pct">${d.percent}%</span>
        </div>
        <div class="bar-track">
          <div class="bar-fill" style="width:${d.percent}%; background:${barColor(d.percent)}"></div>
        </div>
        <div class="bar-meta">
          <span>${d.used} used</span>
          <span>${d.avail} free / ${d.size}</span>
        </div>
      </div>`).join('');
  } else {
    diskList.innerHTML = '<span class="offline-msg">No disk data</span>';
  }

  // Timestamp
  const now = new Date();
  document.getElementById('updated').textContent =
    'Updated ' + now.toLocaleTimeString();
}

async function poll() {
  try {
    const res = await fetch('/api/stats');
    if (res.ok) update(await res.json());
  } catch (e) {
    console.warn('fetch error', e);
  }
}

poll();
setInterval(poll, 2000);
</script>
</body>
</html>
"""

# ── HTTP handler ──────────────────────────────────────────────────────────────

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        pass  # silence access log

    def do_GET(self):
        path = urlparse(self.path).path
        if path == "/api/stats":
            data = json.dumps(get_stats()).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", len(data))
            self.end_headers()
            self.wfile.write(data)
        else:
            body = HTML.encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", len(body))
            self.end_headers()
            self.wfile.write(body)


# ── Entry point ───────────────────────────────────────────────────────────────

if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 7070
    server = HTTPServer(("0.0.0.0", port), Handler)
    print(f"Hardware Monitor running at http://localhost:{port}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopped.")
