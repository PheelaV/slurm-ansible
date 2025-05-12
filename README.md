# Slurm Cluster Ansible Deployment

This was entirely developed with the assistance of Claude Sonnet 3.7. The entire ansible playbook can be summarized by using the [summarize_playbook](./summarize_playbook.py) script in root:

```sh
uv run summarize_playbook.py ./ansible
```

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

### Common Tag Usage

Run specific tagged tasks:

```bash
# Update database credentials only
ansible-playbook -i inventory.ini site.yml --tags=database_credentials

# Update all database-related components
ansible-playbook -i inventory.ini site.yml --tags=database

# Update configuration files
ansible-playbook -i inventory.ini site.yml --tags=config
```

Test changes without applying them:

```bash
# Dry run for database credential updates
ansible-playbook -i inventory.ini site.yml --tags=database_credentials --check
```

### Maintenance Procedures

#### Updating Database Credentials

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

#### Troubleshooting Database Connectivity

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

### Technical Notes

- The `update_password: always` parameter in the MySQL user task ensures passwords are updated when changed in the vault.
- Password quoting in slurmdbd.conf is critical for proper database connectivity.
- Database verification tasks ensure connections are tested after any credential changes.

### Security Considerations

- Remember that this deployment uses an SSH key for Ansible Vault password management for demonstration purposes only.
- In production, follow the recommendations in `SECURITY_WARNING.md` for proper credential management.

## Testing

Using a simple [script](./simple_test_suite.sh).

WIP: Using [bats](https://bats-core.readthedocs.io/en/stable/installation.html)

# Slurm Cluster BATS Tests

This directory contains automated tests for the Slurm cluster using BATS (Bash Automated Testing System).

## Test Structure

Tests are organized into multiple files:

- `01-environment.bats`: Basic environment and hostname resolution tests
- `02-daemons.bats`: Service status and Munge authentication tests
- `03-job-submission.bats`: Basic job submission tests
- `04-multinode.bats`: Multi-node job tests
- `05-accounting.bats`: Accounting verification tests

Supporting files:
- `config.sh`: Configuration variables
- `helpers.bash`: Helper functions used by tests
- `run_tests.sh`: Test runner script

## Running Tests

### Run all tests:
```bash
./run_tests.sh
```

### Run specific test files:
```bash
./run_tests.sh 01-environment.bats
```

### Run tests with a filter:
```bash
./run_tests.sh --filter "daemon"
```

### Run only environment tests:
```bash
./run_tests.sh --env-only
```

### Run only job submission tests:
```bash
./run_tests.sh --job-only
```

### Clean up after tests:
```bash
./run_tests.sh --cleanup
```

## Test Reports

After running the tests, two files will be created in the `../logs` directory:
- A log file with the raw test output
- An HTML report with formatted results

## Adding New Tests

To add new tests, either:
1. Add test cases to the existing files
2. Create new test files following the BATS format

Example test case:
```bash
@test "My new test" {
  run ssh $CONTROLLER "some_command"
  [ "$status" -eq 0 ]
}
```

## Configuration

Edit `config.sh` to update:
- Controller and compute node addresses
- Test directory paths
- Wait times and other parameters