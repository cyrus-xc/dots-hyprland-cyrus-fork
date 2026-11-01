#!/usr/bin/env python3
"""Read package/GPU sensors and publish non-sensitive metrics for end-4."""
import csv
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import time

STATUS = Path('/run/end4-hardware/status.json')

def number(value):
    try:
        return float(value)
    except (ValueError, TypeError):
        return None

def read(path):
    try:
        return Path(path).read_text().strip()
    except OSError:
        return ''

def usage(current, previous):
    if previous is None:
        return None
    total = current[0] - previous[0]
    idle = current[1] - previous[1]
    return max(0.0, min(1.0, 1 - idle / total)) if total > 0 else None

def power_watts(energy, previous, elapsed, maximum):
    if previous is None or elapsed <= 0 or maximum <= 0:
        return None
    delta = (energy - previous) % maximum
    watts = delta / 1_000_000 / elapsed
    return round(watts, 2) if 0 <= watts <= 2000 else None

class Collector:
    def __init__(self):
        self.topology = {}
        self.topology_time = 0
        self.previous_cpu = {}
        self.previous_energy = {}
        self.previous_time = None

    def cpu_packages(self, now):
        if now - self.topology_time > 30 or not self.topology:
            topology = {}
            for path in Path('/sys/devices/system/cpu').glob('cpu[0-9]*'):
                if not re.fullmatch(r'cpu\d+', path.name):
                    continue
                socket = read(path/'topology/physical_package_id')
                if socket.isdigit():
                    topology[int(path.name[3:])] = int(socket)
            self.topology = topology
            self.topology_time = now
        stats = {}
        for line in read('/proc/stat').splitlines():
            fields = line.split()
            if not fields or not re.fullmatch(r'cpu\d+', fields[0]):
                continue
            socket = self.topology.get(int(fields[0][3:]))
            if socket is None:
                continue
            values = list(map(int, fields[1:9]))  # guest time is already included
            group = stats.setdefault(socket, [0, 0, 0])
            group[0] += sum(values)
            group[1] += values[3] + values[4]  # idle + iowait
            group[2] += 1
        frequencies = {}
        for block in read('/proc/cpuinfo').split('\n\n'):
            fields = dict(line.split(':', 1) for line in block.splitlines() if ':' in line)
            fields = {key.strip(): value.strip() for key, value in fields.items()}
            cpu = fields.get('processor', '')
            mhz = number(fields.get('cpu MHz'))
            if cpu.isdigit() and mhz is not None and int(cpu) in self.topology:
                frequencies.setdefault(self.topology[int(cpu)], []).append(mhz)
        energy = {}
        for path in Path('/sys/class/powercap').glob('*'):
            match = re.fullmatch(r'package-(\d+)', read(path/'name'))
            if not match:
                continue
            value = number(read(path/'energy_uj'))
            maximum = number(read(path/'max_energy_range_uj'))
            if value is not None and maximum is not None:
                energy[int(match.group(1))] = (value, maximum)
        result = []
        elapsed = now - self.previous_time if self.previous_time is not None else 0
        for socket, values in sorted(stats.items()):
            watts = None
            if socket in energy:
                watts = power_watts(energy[socket][0], self.previous_energy.get(socket), elapsed, energy[socket][1])
            clocks = frequencies.get(socket, [])
            result.append({'id':socket,'logicalCpus':values[2],
                'usage':usage(values, self.previous_cpu.get(socket)),
                'frequencyMhz':round(sum(clocks)/len(clocks), 1) if clocks else None,
                'powerWatts':watts})
        self.previous_cpu = stats
        self.previous_energy = {key:value[0] for key,value in energy.items()}
        self.previous_time = now
        return result

    def gpus(self):
        result = []
        if shutil.which('nvidia-smi'):
            query = 'index,uuid,name,pci.bus_id,utilization.gpu,temperature.gpu,power.draw,memory.used,memory.total,clocks.current.graphics,clocks.current.memory'
            try:
                process = subprocess.run(['nvidia-smi','--query-gpu='+query,'--format=csv,noheader,nounits'],
                    capture_output=True,text=True,timeout=2,check=True,env={**os.environ,'LC_ALL':'C'})
                for row in csv.reader(process.stdout.splitlines(),skipinitialspace=True):
                    if len(row) != 11:
                        continue
                    load = number(row[4])
                    result.append({'id':row[1],'vendor':'NVIDIA','vendorIndex':int(row[0]),'name':row[2],
                        'pciAddress':row[3],'usage':load/100 if load is not None else None,
                        'temperatureC':number(row[5]),'powerWatts':number(row[6]),
                        'memoryUsedMib':number(row[7]),'memoryTotalMib':number(row[8]),
                        'frequencyMhz':number(row[9]),'memoryFrequencyMhz':number(row[10])})
            except (OSError, subprocess.SubprocessError):
                pass
        # AMD discrete GPUs expose the same metrics through DRM/hwmon.
        for card in Path('/sys/class/drm').glob('card[0-9]*'):
            if not re.fullmatch(r'card\d+', card.name) or read(card/'device/vendor') != '0x1002':
                continue
            device = card/'device'
            sensors = sorted((device/'hwmon').glob('hwmon*'))
            sensor = sensors[0] if sensors else Path('/nonexistent')
            def scaled(path, divisor):
                value = number(read(path))
                return value/divisor if value is not None else None
            def clock(path):
                active = next((line for line in read(path).splitlines() if '*' in line), '')
                match = re.search(r'(\d+)\s*[mM][hH][zZ]', active)
                return float(match.group(1)) if match else None
            result.append({'id':device.resolve().name,'vendor':'AMD','name':'AMD GPU · '+device.resolve().name,
                'pciAddress':device.resolve().name,'usage':scaled(device/'gpu_busy_percent',100),
                'temperatureC':scaled(sensor/'temp1_input',1000),
                'powerWatts':scaled(sensor/'power1_average',1_000_000) or scaled(sensor/'power1_input',1_000_000),
                'memoryUsedMib':scaled(device/'mem_info_vram_used',1048576),
                'memoryTotalMib':scaled(device/'mem_info_vram_total',1048576),
                'frequencyMhz':clock(device/'pp_dpm_sclk'),'memoryFrequencyMhz':clock(device/'pp_dpm_mclk')})
        result.sort(key=lambda gpu:(gpu['vendor'],gpu['pciAddress']))
        for index, gpu in enumerate(result):
            gpu['index'] = index
        return result

def publish(data):
    fd, temporary = tempfile.mkstemp(prefix='.status-',dir=STATUS.parent)
    try:
        with os.fdopen(fd,'w') as stream:
            json.dump(data,stream,allow_nan=False,separators=(',',':'))
        os.chmod(temporary,0o644)
        os.replace(temporary,STATUS)
    finally:
        if os.path.exists(temporary): os.unlink(temporary)

def main():
    collector = Collector()
    while True:
        start = time.monotonic()
        try:
            publish({'schemaVersion':1,'timestamp':time.time(),'cpuPackages':collector.cpu_packages(start),'gpus':collector.gpus()})
        except Exception as error:
            print(type(error).__name__+': '+str(error),flush=True)
        time.sleep(max(0.1,2-(time.monotonic()-start)))

if __name__ == '__main__':
    main()
