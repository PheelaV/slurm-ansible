#!/usr/bin/env bats

# Load helpers
load "helpers.bash"

# Setup function runs before each test
setup() {
  setup_test_env
}

# Teardown function runs after all tests
teardown() {
  true  # No need to clean up after environment tests
}

@test "Check Slurm configuration" {
  run ssh $CONTROLLER 'scontrol show config | grep -E "(SlurmdSpoolDir|JobFileAppend|DefaultStorageLoc)"'
  [ "$status" -eq 0 ]
}

@test "Verify test directory permissions" {
  run ssh $CONTROLLER "ls -la $TEST_DIR"
  [ "$status" -eq 0 ]
}

@test "Resolve compute-1 from controller" {
  run ssh $CONTROLLER "ping -c 1 slurm-compute-1"
  [ "$status" -eq 0 ]
}

@test "Resolve compute-2 from controller" {
  run ssh $CONTROLLER "ping -c 1 slurm-compute-2"
  [ "$status" -eq 0 ]
}

@test "Resolve controller from compute-1" {
  run ssh ${COMPUTE_NODES[0]} "ping -c 1 slurm-controller"
  [ "$status" -eq 0 ]
}
