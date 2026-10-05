#!/bin/bash

echo "======================================"
echo " Verificación de Ubuntu Server"
echo "======================================"

echo
echo "1. Hostname del servidor:"
hostname

echo
echo "2. Particiones y sistemas de archivos:"
lsblk -f

echo
echo "3. Estado del servicio SSH:"
systemctl status ssh --no-pager

echo
echo "4. Estado del socket SSH:"
systemctl status ssh.socket --no-pager

echo
echo "5. Configuración de red:"
ip addr

echo
echo "======================================"
echo " Verificación finalizada"
echo "======================================"