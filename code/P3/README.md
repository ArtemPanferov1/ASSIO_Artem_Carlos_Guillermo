# Práctica 3 · AURORA-6

| Rol | Cuenta del servicio | Unidad | Simulador original |
| --- | --- | --- | --- |
| A · Guillermo (Windows) | `guillermo_a` | `Guillermo_A/structure-monitor.service` | `structure-monitor.sh` |
| B · Carlos (macOS) | `usuario_b` | `Carlos_B/telemetry-monitor.service` | `telemetry-monitor.sh` |

Los dos simuladores conservan los bytes del ZIP docente. Las unidades se reconstruyeron a partir de las memorias, sin una exportación verificada de las VM. En cada VM se espera el ejecutable en `/opt/aurora6/tools/` con propietario `root:root` y modo `755`, y la unidad en `/etc/systemd/system/` con propietario `root:root` y modo `644`. Para contrastar la reconstrucción con la instalación, consulta `systemctl cat` para la unidad del rol y revisa sus posibles archivos de configuración adicionales.

Las unidades aplican `NoNewPrivileges=true`, `PrivateTmp=true`, `ProtectHome=true` y `ProtectSystem=full`. La recuperación se configura con `Restart=on-failure` y `RestartSec=3`.

## Verificación en Ubuntu Server

Ejecuta en la VM de Guillermo:

```bash
sudo bash Verificacion/verificacion_aurora6_p3.sh A
```

Ejecuta en la VM de Carlos:

```bash
sudo bash Verificacion/verificacion_aurora6_p3.sh B
```

El verificador comprueba la identidad del equipo, la cuenta del servicio, los archivos y permisos, el estado y las propiedades de systemd. Cuenta hasta 20 entradas visibles de la última hora del journal de la unidad sin imprimir mensajes. Consulta `PermitRootLogin` mediante `sshd -T` para un contexto de bucle local. Si hay bloques `Match`, usa también el contexto de conexión correspondiente en la VM. Las comprobaciones de solo lectura devuelven `0` si se completan sin avisos, `1` si quedan comprobaciones pendientes y `2` ante un uso incorrecto.

## Validaciones de la entrega

Se comprobó la sintaxis con `bash -n` de los dos simuladores y del verificador, y la coincidencia binaria de los simuladores con el ZIP del profesor. Quedan pendientes `systemd-analyze verify` en Linux y el contraste con las unidades y la configuración efectiva de las VM. Las pruebas de recuperación realizadas por los integrantes se recogen en la memoria conjunta.
