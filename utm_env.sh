#!/usr/bin/env bash

# UTM Slurm VMs management script
# Provides functionality to start/stop VMs and recover backups
# Only processes VMs with "slurm" in the name

set -euo pipefail

# Function to list all Slurm VMs with their status
list_vms() {
    echo "Listing all Slurm VMs:"
    utmctl list | grep "slurm"
}

# Function to start original Slurm VMs (non-backups)
start_vms() {
    local vms

    # Get all original VMs with "slurm" in the name that are stopped
    vms=$(utmctl list | grep "slurm" | grep -v "backup" | grep "stopped" | awk '{print $1}')

    if [[ -z "$vms" ]]; then
        echo "No stopped Slurm VMs found."
        return 0
    fi

    # Start each VM
    for vm_uuid in $vms; do
        vm_name=$(utmctl list | grep "$vm_uuid" | awk '{$1=""; $2=""; print $0}' | sed 's/^  //')
        echo "Starting VM: $vm_name ($vm_uuid)"
        utmctl start "$vm_uuid"
    done

    echo "All Slurm VMs have been started."
}

# Function to stop original Slurm VMs (non-backups)
stop_vms() {
    local vms

    # Get all original VMs with "slurm" in the name that are running
    vms=$(utmctl list | grep "slurm" | grep -v "backup" | grep "started" | awk '{print $1}')

    if [[ -z "$vms" ]]; then
        echo "No running Slurm VMs found."
        return 0
    fi

    # Stop each VM
    for vm_uuid in $vms; do
        vm_name=$(utmctl list | grep "$vm_uuid" | awk '{$1=""; $2=""; print $0}' | sed 's/^  //')
        echo "Stopping VM: $vm_name ($vm_uuid)"
        utmctl stop "$vm_uuid"
    done

    echo "All Slurm VMs have been stopped."
}

# Function to start backup Slurm VMs
start_backups() {
    local backup_vms

    # Get all VMs with "slurm" and "backup" in the name that are stopped
    backup_vms=$(utmctl list | grep "slurm" | grep "backup" | grep "stopped" | awk '{print $1}')

    if [[ -z "$backup_vms" ]]; then
        echo "No stopped Slurm backup VMs found."
        return 0
    fi

    # Start each backup VM
    for vm_uuid in $backup_vms; do
        vm_name=$(utmctl list | grep "$vm_uuid" | awk '{$1=""; $2=""; print $0}' | sed 's/^  //')
        echo "Starting backup VM: $vm_name ($vm_uuid)"
        utmctl start "$vm_uuid"
    done

    echo "All Slurm backup VMs have been started."
}

# Function to stop backup Slurm VMs
stop_backups() {
    local backup_vms

    # Get all VMs with "slurm" and "backup" in the name that are running
    backup_vms=$(utmctl list | grep "slurm" | grep "backup" | grep "started" | awk '{print $1}')

    if [[ -z "$backup_vms" ]]; then
        echo "No running Slurm backup VMs found."
        return 0
    fi

    # Stop each backup VM
    for vm_uuid in $backup_vms; do
        vm_name=$(utmctl list | grep "$vm_uuid" | awk '{$1=""; $2=""; print $0}' | sed 's/^  //')
        echo "Stopping backup VM: $vm_name ($vm_uuid)"
        utmctl stop "$vm_uuid"
    done

    echo "All Slurm backup VMs have been stopped."
}

# Function to recover from backup
recover_backups() {
    # First, let's make sure all VMs are stopped to avoid conflicts
    echo "Ensuring all Slurm VMs are stopped before recovery..."
    stop_vms

    # Get all original Slurm VM information
    local original_vms
    original_vms=$(utmctl list | grep "slurm" | grep -v "backup" | grep -v "removed" | awk '{print $1 ":" $3 " " $4 " " $5 " " $6 " " $7}')

    # Check if original VMs exist
    if [[ -z "$original_vms" ]]; then
        echo "No original Slurm VMs found to recover."
        return 1
    fi

    echo "Recovery process starting..."

    # Process each original VM
    while IFS=: read -r uuid name_with_spaces; do
        # Clean up name by removing leading/trailing spaces
        name=$(echo "$name_with_spaces" | sed 's/^[ \t]*//;s/[ \t]*$//')

        if [[ -z "$name" || "$name" == *"--removed"* ]]; then
            continue
        fi

        # Find corresponding backup VM
        backup_info=$(utmctl list | grep "$name backup")
        backup_uuid=$(echo "$backup_info" | awk '{print $1}')

        if [[ -z "$backup_uuid" ]]; then
            echo "No backup found for VM: $name (UUID: $uuid)"
            continue
        fi

        echo "Processing recovery for VM: $name"

        # 1. Rename original VM by cloning with --removed suffix
        echo "  Creating renamed copy of original VM as '$name --removed'"
        removed_name="$name --removed"
        utmctl clone "$uuid" --name "$removed_name" >/dev/null 2>&1 || {
            echo "Failed to clone original VM"
            continue
        }

        # 2. Delete the original VM
        echo "  Deleting original VM"
        utmctl delete "$uuid"

        # 3. Clone the backup VM with the original name
        echo "  Cloning backup VM as original name: $name"
        utmctl clone "$backup_uuid" --name "$name" >/dev/null 2>&1 || {
            echo "Failed to clone backup VM"
            continue
        }

        echo "  Recovery completed for VM: $name"
    done <<<"$original_vms"

    echo "Recovery process completed!"
}

# Print usage information
show_help() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  list           - List all Slurm VMs with their status"
    echo "  start-vms      - Start all stopped original Slurm VMs"
    echo "  stop-vms       - Stop all running original Slurm VMs"
    echo "  start-backups  - Start all stopped backup Slurm VMs"
    echo "  stop-backups   - Stop all running backup Slurm VMs"
    echo "  recover        - Recover original VMs from their backups"
    echo "  help           - Show this help message"
}

# Main function to handle script execution
main() {
    if [[ $# -eq 0 ]]; then
        echo "No command specified"
        show_help
        exit 1
    fi

    local command="$1"

    case "$command" in
    "list")
        list_vms
        ;;
    "start-vms")
        start_vms
        ;;
    "stop-vms")
        stop_vms
        ;;
    "start-backups")
        start_backups
        ;;
    "stop-backups")
        stop_backups
        ;;
    "recover")
        recover_backups
        ;;
    "help" | "--help" | "-h")
        show_help
        ;;
    *)
        echo "Unknown command: $command"
        show_help
        exit 1
        ;;
    esac
}

# Execute the main function with all arguments
main "$@"
