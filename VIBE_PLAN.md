# Objective: Basic Slurm Cluster on Apple Silicon using UTM

## Components

UTM (for VM management on Apple Silicon)
Ubuntu Server 22.04 LTS ARM64 (base OS)
Ansible (for automation)
Munge (for authentication)
Slurm (workload manager)

## Cluster Architecture

1 controller node (runs slurmctld, slurmdbd, and MariaDB)
2+ compute nodes (run slurmd)
Shared network for inter-node communication

## Implementation Steps

### Phase 1: VM Creation and Base Setup

Install UTM on macOS
Create a template Ubuntu VM in UTM

ARM64 architecture for native performance
Minimal installation with SSH server
Bridged networking for inter-VM communication

Clone the template to create controller and compute nodes
Configure networking on each VM (static IPs recommended)
Setup SSH key-based authentication between your Mac and all VMs

### Phase 2: Ansible Configuration

Create Ansible inventory defining controller and compute nodes
Develop role structure for modular automation
Create common role for shared configurations
Create specialized roles for controller and compute nodes

### Phase 3: Cluster Deployment

Deploy Munge authentication across all nodes
Install and configure MariaDB on controller
Install Slurm packages on all nodes
Configure controller-specific services
Configure compute node services
Test basic cluster functionality
Setup a simple shared filesystem (optional)

## Learning Outcomes

VM networking on Apple Silicon
Ansible automation for configuration management
Slurm architecture and configuration
Cluster authentication with Munge
Basic HPC job scheduling
