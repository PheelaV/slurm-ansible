#!/bin/bash
# check_slurmd.sh - Check slurmd status and logs on compute nodes

echo "=== slurmd Service Status ==="
systemctl status slurmd

echo -e "\n=== slurmd Service Logs ==="
journalctl -xeu slurmd.service --no-pager | tail -n 30

echo -e "\n=== slurm.conf Content ==="
cat /etc/slurm/slurm.conf

echo -e "\n=== Slurm File Permissions ==="
ls -la /etc/slurm/
ls -la /var/spool/slurm/