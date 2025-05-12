#!/bin/bash
# diagnostic.sh - Script to check time and Slurm configuration

echo "=== System Time Information ==="
date
timedatectl

echo -e "\n=== Chrony Status ==="
systemctl status chronyd
chronyc sources
chronyc tracking

echo -e "\n=== APT Update Test ==="
apt-get update -o Acquire::Check-Valid-Until=false

echo -e "\n=== Slurm Configuration Files ==="
ls -la /etc/slurm/