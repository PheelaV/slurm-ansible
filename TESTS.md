# Slurm Cluster BATS Tests

[main](./README.md)
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

### Run all tests

```bash
./run_tests.sh
```

### Run specific test files

```bash
./run_tests.sh 01-environment.bats
```

### Run tests with a filter

```bash
./run_tests.sh --filter "daemon"
```

### Run only environment tests

```bash
./run_tests.sh --env-only
```

### Run only job submission tests

```bash
./run_tests.sh --job-only
```

### Clean up after tests

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
