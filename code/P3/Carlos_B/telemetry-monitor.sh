#!/bin/bash
# AURORA-6 | Simulación de la recepción de tramas de telemetría.
set -eu

trama=1
printf 'Telemetría | simulador iniciado | PID=%s\n' "$$"
while true; do
    latencia_ms=$((20 + RANDOM % 41))
    printf 'Telemetría | trama=%d recibida | latencia=%d ms\n' \
        "$trama" "$latencia_ms"
    trama=$((trama + 1))
    sleep 10
done
