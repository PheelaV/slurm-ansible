# Shared Storage for Slurm Cluster

[main](./README.md)

This document explains the shared storage implementation for the Slurm cluster, which enables job output files to be accessible across all nodes.

## Overview

The shared storage solution uses NFS (Network File System) to create a common filesystem accessible by all nodes in the cluster:

- The controller node acts as the NFS server, exporting `/shared`
- All compute nodes mount this directory
- Job output files are stored in this shared location
- Users can access their job outputs from the controller node

## Implementation Details

### NFS Server (Controller Node)

- Exports `/shared` to all cluster nodes
- Sets appropriate permissions (777 for testing environment)
- Creates a dedicated `/shared/slurm_tests` directory for testing

### NFS Clients (Compute Nodes)

- Mount the `/shared` directory from the controller
- Have full read/write access to the shared filesystem

### Integration with Slurm

A Lua job submission plugin helps direct job outputs to the shared filesystem. This ensures that:

1. Job outputs go to the shared directory
2. Users can access their job outputs from the controller node
3. Tests can verify job completion by checking output files

## Usage

### For Users

When submitting jobs:

```bash
# Navigate to the shared directory
cd /shared

# Submit a job
sbatch my_job.sh
```

All job outputs will be accessible from the controller node at `/shared`.

### For Testing

The BATS tests use `/shared/slurm_tests` as the test directory:

```bash
# Update in tests/config.sh
TEST_DIR="/shared/slurm_tests"
```

With this setup, job outputs will be visible to the tests running on the controller.

## Ansible Configuration

The shared storage is configured by the `shared_storage` role which:

1. Installs and configures NFS server on the controller
2. Installs and configures NFS clients on compute nodes
3. Sets up the Slurm job submit plugin
4. Verifies the shared storage is working

To apply only the shared storage configuration:

```bash
ansible-playbook -i inventory.ini site.yml --tags=shared_storage
```

## Troubleshooting

If you encounter issues with shared storage:

1. Verify NFS services are running:

   ```bash
   # On controller
   systemctl status nfs-kernel-server
   
   # On compute nodes
   systemctl status nfs-common
   ```

2. Check mounts on compute nodes:

   ```bash
   mount | grep shared
   ```

3. Test file access:

   ```bash
   # On controller
   touch /shared/test_file
   
   # On compute nodes
   ls -la /shared/test_file
   ```

4. Check NFS logs:

   ```bash
   dmesg | grep nfs
   ```
