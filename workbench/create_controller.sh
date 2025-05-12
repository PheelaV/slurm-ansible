#!/bin/bash

# Create the VM
utmctl create --name "slurm-controller" \
  --cpu 2 \
  --memory 4G \
  --disk 20G \
  --iso ~/Downloads/ubuntu-24.04.2-live-server-arm64.iso \
  --architecture arm64 \
  --boot-iso

