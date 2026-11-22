#!/bin/bash
# AURORA-6 | Simulación de dos sensores de la estructura.
set -eu

printf 'Estructura | simulador iniciado | PID=%s\n' "$$"
while true; do
    vibracion_mg=$((8 + RANDOM % 13))
    deformacion_um=$((30 + RANDOM % 21))
    printf 'Estructura | vibración=%d mg | deformación=%d µm\n' \
        "$vibracion_mg" "$deformacion_um"
    sleep 10
done
