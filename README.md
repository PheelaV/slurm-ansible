# Slurm Cluster Ansible Deployment

This project provides an automated deployment of a Slurm cluster using Ansible, tested on Apple Silicon using UTM virtualization. The entire ansible playbook was developed with the assistance of Claude Sonnet 3.7.

## Overview

This repository contains:

- **Ansible playbooks** for automated deployment of a Slurm HPC cluster
- **BATS tests** for validating cluster functionality
- **Utility scripts** for cluster management and diagnostics
- **Documentation** covering setup, testing, and maintenance procedures

You can generate a summary of the entire Ansible playbook using the script in root:

```sh
uv run summarize_playbook.py ./ansible
```

## Cluster Architecture

- **1 controller node** (runs slurmctld, slurmdbd, and MariaDB)
- **2+ compute nodes** (run slurmd)
- **Shared NFS storage** for inter-node file access
- **Network configuration** for cluster communication

By default, the cluster uses the following IP addresses:

- Controller: 192.168.64.10
- Compute-1: 192.168.64.11
- Compute-2: 192.168.64.12

## Key Features

- **Fully automated deployment** using Ansible
- **Shared storage** via NFS for job outputs and data sharing
- **Database integration** for Slurm accounting
- **Automated testing** using BATS
- **Tagged operations** for targeted maintenance
- **Security considerations** for production deployment

## Transitioning to Production Security

When moving to production:

1. Generate new secure passwords
2. Remove `.vault_password` file
3. Re-encrypt vault with a secure password:
    - `ansible-vault rekey --new-vault-password-file=/dev/tty group_vars/all/vault.yml`
4. Remove the `vault_password_file` line from ansible.cfg
5. Use `--ask-vault-pass` flag when running playbooks

## Tags for Targeted Operations

The Ansible playbook includes tags to enable targeted operations on specific components of the Slurm cluster. This allows for efficient maintenance and troubleshooting without running the full playbook.

### Available Tags

| Tag                  | Description                                           | Components Affected                                |
|----------------------|-------------------------------------------------------|----------------------------------------------------|
| `database_credentials` | Updates database credentials for Slurm accounting     | MariaDB user, slurmdbd.conf                        |
| `database`            | General database operations                           | MariaDB database, users, permissions               |
| `config`              | Configuration file updates                            | slurm.conf, slurmdbd.conf                          |
| `shared_storage`      | Configures the shared storage                         | NFS server, clients, and job submit plugins        |

### Common Tag Usage

Run specific tagged tasks:

```bash
# Update database credentials only
ansible-playbook -i inventory.ini site.yml --tags=database_credentials

# Update all database-related components
ansible-playbook -i inventory.ini site.yml --tags=database

# Update configuration files
ansible-playbook -i inventory.ini site.yml --tags=config

# Configure shared storage
ansible-playbook -i inventory.ini site.yml --tags=shared_storage
```

Test changes without applying them:

```bash
# Dry run for database credential updates
ansible-playbook -i inventory.ini site.yml --tags=database_credentials --check
```

## Maintenance Procedures

### Updating Database Credentials

If you need to update the Slurm database password:

1. Update the password in the Ansible vault:

   ```bash
   ansible-vault edit group_vars/all/vault.yml
   ```

2. Run the targeted playbook:

   ```bash
   ansible-playbook -i inventory.ini site.yml --tags=database_credentials
   ```

3. Verify the services are working:

   ```bash
   ssh slurmadmin@192.168.64.10 "sacct -X --format=JobID,JobName,State | head -5"
   ```

### Troubleshooting Database Connectivity

If Slurm accounting services (slurmdbd) cannot connect to the database:

1. Verify configuration format:

   ```bash
   ssh slurmadmin@192.168.64.10 "sudo cat /etc/slurm/slurmdbd.conf | grep StoragePass"
   ```

   **Important**: The password in slurmdbd.conf must be in quotes: `StoragePass="yourpassword"`

2. Test database connectivity manually:

   ```bash
   ssh slurmadmin@192.168.64.10 "sudo -u slurm mysql -u slurm -p'yourpassword' slurm_acct_db -e 'SELECT 1;'"
   ```

3. If manual connection works but slurmdbd fails, restart the service:

   ```bash
   ssh slurmadmin@192.168.64.10 "sudo systemctl restart slurmdbd"
   ```

## Shared Storage

The cluster includes a shared NFS storage system to ensure job outputs are accessible across all nodes.

### Shared Storage Features

- Controller node exports the `/shared` directory
- Compute nodes mount this shared directory
- Job output files are stored in this location
- Users can access job outputs from any node

See [SHARED_STORAGE.md](./SHARED_STORAGE.md) for detailed information on the shared storage implementation.

## Testing

The repository includes a comprehensive testing framework using [BATS](https://bats-core.readthedocs.io/en/stable/installation.html) (Bash Automated Testing System).

### Test Structure

Tests are organized into multiple files:

- `01-environment.bats`: Basic environment and hostname resolution tests
- `02-daemons.bats`: Service status and Munge authentication tests
- `03-submission.bats`: Basic job submission tests
- `04-multinode.bats`: Multi-node job tests
- `05-accounting.bats`: Accounting verification tests

### Running Tests

```bash
# Run all tests
./tests/run_tests.sh

# Run specific test files
./tests/run_tests.sh 01-environment.bats

# Run tests with a filter
./tests/run_tests.sh --filter "daemon"
```

See [TESTS.md](./TESTS.md) for more information on running and extending the test suite.

## Technical Notes

- The `update_password: always` parameter in the MySQL user task ensures passwords are updated when changed in the vault.
- Password quoting in slurmdbd.conf is critical for proper database connectivity.
- Database verification tasks ensure connections are tested after any credential changes.

## Security Considerations

- This deployment uses an SSH key for Ansible Vault password management for demonstration purposes only.
- In production environments, follow the recommendations in [SECURITY_WARNING.md](./ansible/SECURITY_WARNING.md) for proper credential management.
- Always revoke default credentials and replace them with secure alternatives before production use.

## Related Documentation

- [TESTS.md](./TESTS.md) - Detailed information on test structure and execution
- [SHARED_STORAGE.md](./SHARED_STORAGE.md) - NFS shared storage implementation details
- [VIBE_PLAN.md](./VIBE_PLAN.md) - Original implementation plan for the cluster
- [SECURITY_WARNING.md](./ansible/SECURITY_WARNING.md) - Security considerations and best practices
