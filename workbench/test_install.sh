#!/bin/bash
# Script to test Slurm installation manually

# Update package lists
sudo apt update

# Try installing just the essential packages with verbose output
sudo apt install -y --no-install-recommends slurmd

# If that fails, try installing with minimal dependencies
echo "If the above failed, trying minimal install..."
sudo apt install -y --no-install-recommends slurm-client