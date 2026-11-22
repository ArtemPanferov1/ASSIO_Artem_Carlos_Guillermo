#!/usr/bin/env bash
# P3 AURORA-6: compruebo una instalacion de un servicio systemd sin modificarla.
# Uso: bash verificacion_aurora6_p3.sh A   (Guillermo)
#      bash verificacion_aurora6_p3.sh B   (Carlos)
set -u -o pipefail
if (( $# != 1 )); then
  printf 'Uso: bash %s A|B\n' "$0"
  exit 2
fi
role="$1"
case "$role" in
  A|a) unit=structure-monitor.service; script=structure-monitor.sh; user=guillermo_a ;;
  B|b) unit=telemetry-monitor.service; script=telemetry-monitor.sh; user=usuario_b ;;
  *) printf 'Uso: bash %s A|B\n' "$0"; exit 2 ;;
esac
source_file="/opt/aurora6/tools/$script"
unit_file="/etc/systemd/system/$unit"
fail=0
ok() { printf '[OK] %s\n' "$1"; }
warn() { printf '[PENDIENTE] %s\n' "$1"; fail=$((fail+1)); }

printf '=== Verificacion P3 | Rol %s | %s ===\n' "$role" "$unit"
printf '  Equipo: %s | Kernel: %s | Usuario: %s\n' "$(uname -n)" "$(uname -sr)" "$(id -un)"
# Compruebo que la cuenta del rol existe en el equipo donde ejecuto el servicio.
if id "$user" >/dev/null 2>&1; then ok "Existe el usuario $user"; else warn "No existe $user"; fi
# Compruebo que el ejecutable original existe, es valido para Bash y esta protegido.
if [[ -f "$source_file" ]]; then
  ok "Existe $source_file"
  if bash -n "$source_file"; then ok 'Sintaxis Bash valida'; else warn 'Error de sintaxis Bash'; fi
  if [[ -x "$source_file" ]]; then ok 'Script ejecutable'; else warn 'Script sin permiso de ejecucion'; fi
  owner=$(stat -c '%U:%G' "$source_file" 2>/dev/null || true)
  mode=$(stat -c '%a' "$source_file" 2>/dev/null || true)
  printf '  Script: propietario=%s modo=%s\n' "$owner" "$mode"
  [[ "$owner" == root:root ]] && ok 'Ejecutable propiedad de root' || warn 'Propietario del ejecutable diferente de root:root'
  [[ "$mode" == 755 ]] && ok 'Ejecutable con modo 755' || warn 'Modo del ejecutable diferente de 755'
else warn "Falta $source_file"; fi
# Compruebo el archivo .service y la configuracion efectiva de systemd.
if [[ -f "$unit_file" ]]; then
  ok "Existe $unit_file"
  uowner=$(stat -c '%U:%G' "$unit_file" 2>/dev/null || true)
  umode=$(stat -c '%a' "$unit_file" 2>/dev/null || true)
  printf '  Unidad: propietario=%s modo=%s\n' "$uowner" "$umode"
  [[ "$uowner" == root:root ]] && ok 'Unidad propiedad de root' || warn 'Unidad sin propietario root:root'
  [[ "$umode" == 644 ]] && ok 'Unidad con modo 644' || warn 'Unidad con modo distinto de 644'
else warn "Falta $unit_file"; fi
if command -v systemctl >/dev/null 2>&1; then
  if systemctl is-active --quiet "$unit"; then ok 'Servicio activo'; else warn 'Servicio no activo'; fi
  if [[ "$(systemctl is-enabled "$unit" 2>/dev/null || true)" == enabled ]]; then ok 'Servicio habilitado'; else warn 'Servicio no habilitado'; fi
  for entry in "User:$user" 'Restart:on-failure' 'RestartUSec:3s' 'NoNewPrivileges:yes' 'PrivateTmp:yes' 'ProtectHome:yes' 'ProtectSystem:full'; do
    key=${entry%%:*}; expected=${entry#*:}
    value=$(systemctl show "$unit" -p "$key" --value 2>/dev/null || true)
    if [[ "$value" == "$expected" ]]; then ok "$key=$value"; else warn "$key: esperado $expected, obtenido ${value:-<vacio>}"; fi
  done
else warn 'systemctl no disponible'; fi
# Compruebo si la configuracion efectiva de SSH bloquea la cuenta root.
if [[ -x /usr/sbin/sshd ]]; then
  if [[ $EUID -eq 0 ]]; then
    effective=$(/usr/sbin/sshd -T -C user=root,host=localhost,addr=127.0.0.1 2>/dev/null | grep -i '^permitrootlogin ' || true)
    [[ "$effective" == 'permitrootlogin no' ]] && ok 'SSH bloquea login directo root' || warn "SSH root: ${effective:-no se pudo consultar}"
  else
    warn 'Ejecuta con sudo para consultar la configuracion efectiva de SSH'
  fi
else warn 'sshd no disponible'; fi
# Resume el journal sin mostrar el texto de los mensajes.
if command -v journalctl >/dev/null 2>&1; then
  if count=$(journalctl -q --no-pager -u "$unit" --since '1 hour ago' -n 20 \
    --output=json --output-fields=__REALTIME_TIMESTAMP | wc -l); then
    printf '  Registros visibles de la ultima hora (max. 20): %d\n' "$count"
  else
    warn 'No se pudo consultar el journal de la unidad'
  fi
else
  warn 'journalctl no disponible'
fi
# No cambio permisos, no reinicio servicios y no simulo fallos.
printf '=== Fin: %d aviso(s)/comprobacion(es) pendientes ===\n' "$fail"
((fail == 0))
