#!/bin/sh
# One sample: /proc/stat's cpu line, MemTotal and MemAvailable, then
# "cputemp <millidegrees>" and either "nvidia <use,temp,used,total>" or
# "amdgpu <use>" where there's such a sensor.
head -1 /proc/stat
grep -E '^(MemTotal|MemAvailable):' /proc/meminfo | tr -s ' ' | cut -d' ' -f1,2
for h in /sys/class/hwmon/hwmon*; do
    case "$(cat "$h/name")" in k10temp|coretemp|zenpower) echo "cputemp $(cat "$h/temp1_input")"; break;; esac
done
if command -v nvidia-smi >/dev/null; then
    echo "nvidia $(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total --format=csv,noheader,nounits | head -1)"
else
    for c in /sys/class/drm/card*/device/gpu_busy_percent; do [ -r "$c" ] && echo "amdgpu $(cat "$c")" && break; done
fi
