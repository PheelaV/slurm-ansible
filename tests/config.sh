#!/bin/bash
# Configuration for Slurm tests

# Cluster access details
CONTROLLER="slurmadmin@192.168.64.10"
COMPUTE_NODES=("slurmadmin@192.168.64.11" "slurmadmin@192.168.64.12")

# Use shared filesystem for tests
TEST_DIR="/shared/slurm_tests"

# Test job scripts
BASIC_JOB_SCRIPT="$TEST_DIR/basic_test.sh"
MULTINODE_JOB_SCRIPT="$TEST_DIR/multinode_test.sh"
RESOURCE_JOB_SCRIPT="$TEST_DIR/resource_test.sh"

# Test parameters
WAIT_TIME_SHORT=15 # seconds
WAIT_TIME_LONG=30  # seconds
