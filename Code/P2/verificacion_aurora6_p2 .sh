#!/usr/bin/env bash
# Practica 2 (88020) - AURORA-6
# Verifico, sin cambiar nada, la configuracion de archivos, cuentas,
# grupos, permisos tradicionales y ACL de mi Ubuntu Server.
# Este script comprueba el entorno montado en la maquina de Guillermo.
# Ejecutar: sudo bash verificacion_aurora6_p2.sh

set -u
ROOT='/srv/aurora6'
ok=0
fail=0

if [[ "$(id -u)" -ne 0 ]]; then
  echo 'ERROR: Ejecuta este script con sudo (necesita revisar directorios protegidos).'
  exit 2
fi
if ! command -v getfacl >/dev/null 2>&1; then
  echo 'ERROR: Falta el paquete acl. Instalar con: sudo apt install acl'
  exit 2
fi

check() {
  local description="$1"; shift
  if "$@" >/dev/null 2>&1; then
    printf '[OK] %s\n' "$description"
    ok=$((ok + 1))
  else
    printf '[FALLO] %s\n' "$description"
    fail=$((fail + 1))
  fi
}

check_denied() {
  local description="$1"; shift
  if "$@" >/dev/null 2>&1; then
    printf '[FALLO] %s (el acceso fue permitido)\n' "$description"
    fail=$((fail + 1))
  else
    printf '[OK] %s (acceso denegado)\n' "$description"
    ok=$((ok + 1))
  fi
}

check_acl() {
  local description="$1" path="$2" rule="$3"
  check "$description" bash -c 'getfacl -cp "$1" 2>/dev/null | grep -Fxq "$2"' bash "$path" "$rule"
}

printf '\n=== AURORA-6 · VERIFICACION DE LA PRACTICA 2 ===\n'
printf 'Fecha: %s\nEquipo: %s\n\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$(hostname)"

printf '%s\n' '1. Estructura de directorios'
for rel in \
  '' 'ingenieria' 'ingenieria/mecanica' 'ingenieria/avionica' \
  'ingenieria/software' 'compras' 'compras/proveedores' \
  'compras/pedidos' 'compras/contabilidad' \
  'compras/contabilidad/facturas' 'documentacion' \
  'documentacion/comun' 'documentacion/confidencial' \
  'intercambio' 'intercambio/incoming' 'intercambio/approved' \
  'intercambio/quarantine'; do
  check "Existe ${ROOT}/${rel}" test -d "${ROOT}/${rel}"
done

printf '\n%s\n' '2. Usuarios y pertenencia a grupos'
for usuario in guillermo_a carlos_b artem_c; do
  check "Existe usuario ${usuario}" id "$usuario"
done
for registro in \
 'guillermo_a mecanica' 'guillermo_a proyecto' \
 'carlos_b avionica' 'carlos_b software' 'carlos_b proyecto' \
 'artem_c compras' 'artem_c proyecto'; do
  read -r usuario grupo <<< "$registro"
  check "${usuario} pertenece a ${grupo}" bash -c 'id -nG "$1" | tr " " "\n" | grep -Fxq "$2"' bash "$usuario" "$grupo"
done

printf '\n%s\n' '3. Permisos DAC y propietarios de grupo'
for registro in \
  'ingenieria/mecanica mecanica' 'ingenieria/avionica avionica' \
  'ingenieria/software software' 'compras compras' \
  'documentacion proyecto' 'documentacion/comun proyecto'; do
  read -r rel grupo <<< "$registro"
  check "Grupo propietario ${rel}: ${grupo}" bash -c \
    '[[ "$(stat -c %G "$1")" == "$2" ]]' bash "$ROOT/$rel" "$grupo"
done
check 'Permiso 751 en documentacion' bash -c \
  '[[ "$(stat -c %a "$1")" == 751 ]]' bash "$ROOT/documentacion"
check 'Permiso 700 en confidencial' bash -c \
  '[[ "$(stat -c %a "$1")" == 700 ]]' bash "$ROOT/documentacion/confidencial"

printf '\n%s\n' '4. ACL de acceso entre departamentos'
check_acl 'Carlos puede leer mecanica' "$ROOT/ingenieria/mecanica" 'user:carlos_b:r-x'
check_acl 'Guillermo puede leer avionica' "$ROOT/ingenieria/avionica" 'user:guillermo_a:r-x'
check_acl 'Artem puede atravesar contabilidad' "$ROOT/compras/contabilidad" 'user:artem_c:--x'
check_acl 'Artem puede leer facturas' "$ROOT/compras/contabilidad/facturas" 'user:artem_c:r-x'

printf '\n%s\n' '5. Comprobaciones de acceso (solo lectura, sin crear archivos)'
check 'Guillermo puede listar mecanica' sudo -u guillermo_a ls "$ROOT/ingenieria/mecanica"
check 'Guillermo puede listar avionica' sudo -u guillermo_a ls "$ROOT/ingenieria/avionica"
check_denied 'Guillermo no puede escribir en avionica' sudo -u guillermo_a test -w "$ROOT/ingenieria/avionica"
check 'Carlos puede listar mecanica' sudo -u carlos_b ls "$ROOT/ingenieria/mecanica"
check_denied 'Carlos no puede escribir en mecanica' sudo -u carlos_b test -w "$ROOT/ingenieria/mecanica"
check 'Carlos puede listar software' sudo -u carlos_b ls "$ROOT/ingenieria/software"
check 'Artem puede listar compras' sudo -u artem_c ls "$ROOT/compras"
check 'Artem puede listar facturas' sudo -u artem_c ls "$ROOT/compras/contabilidad/facturas"
check_denied 'Artem no puede escribir en facturas' sudo -u artem_c test -w "$ROOT/compras/contabilidad/facturas"
for usuario in guillermo_a carlos_b artem_c; do
  check "${usuario} puede listar documentacion comun" sudo -u "$usuario" ls "$ROOT/documentacion/comun"
  check_denied "${usuario} no puede consultar confidencial" sudo -u "$usuario" ls "$ROOT/documentacion/confidencial"
done

printf '\nRESUMEN: %s verificaciones correctas | %s fallidas\n' "$ok" "$fail"
if [[ "$fail" -ne 0 ]]; then exit 1; fi
exit 0
