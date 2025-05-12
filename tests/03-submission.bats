
#!/usr/bin/env bats

# Load helpers
load "helpers.bash"

# Setup function runs before each test
setup() {
  setup_test_env
}

# Teardown function
teardown() {
  # Cancel any remaining jobs
  ssh $CONTROLLER "scancel --user=slurmadmin" 2>/dev/null || true
}

@test "Basic job submission" {
  run ssh $CONTROLLER "cd $TEST_DIR && sbatch basic_test.sh"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Submitted batch job" ]]

  # Extract job ID
  job_id=$(echo "$output" | awk '{print $4}')

  # Check job is in queue
  run ssh $CONTROLLER "squeue -j $job_id -h"
  [ "$status" -eq 0 ] || [ -z "$output" ] # Either still running or already finished
}

@test "Check job status in queue" {
  # Submit job if not already done
  job_id=$(get_job_id_by_name "basic-test")
  if [ -z "$job_id" ]; then
    run ssh $CONTROLLER "cd $TEST_DIR && sbatch basic_test.sh"
    [ "$status" -eq 0 ]
    job_id=$(echo "$output" | awk '{print $4}')
  fi

  # Check queue
  run ssh $CONTROLLER "squeue"
  [ "$status" -eq 0 ]
}

@test "Check job working directory" {
  # Submit job if not already done
  job_id=$(get_job_id_by_name "basic-test")
  if [ -z "$job_id" ]; then
    run ssh $CONTROLLER "cd $TEST_DIR && sbatch basic_test.sh"
    [ "$status" -eq 0 ]
    job_id=$(echo "$output" | awk '{print $4}')
  fi

  # Wait if job still running
  wait_for_job "$job_id" 30 || true

  # Check working directory
  run ssh $CONTROLLER "scontrol show job $job_id | grep WorkDir"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "WorkDir" ]]
}

@test "Wait for basic job completion" {
  # Submit job if not already done
  job_id=$(get_job_id_by_name "basic-test")
  if [ -z "$job_id" ]; then
    run ssh $CONTROLLER "cd $TEST_DIR && sbatch basic_test.sh"
    [ "$status" -eq 0 ]
    job_id=$(echo "$output" | awk '{print $4}')
  fi

  # Wait for job to complete
  sleep 15

  # Check for output file
  run ssh $CONTROLLER "find $TEST_DIR -name \"basic-test-*.out\" 2>/dev/null || echo \"Searching for output file...\""
  [ "$status" -eq 0 ]
  [[ ! "$output" =~ "Searching for output file..." ]]
}

@test "Check possible output locations" {
  run ssh $CONTROLLER "ls -la $TEST_DIR/ /tmp/ ~ | grep -i out"
  [ "$status" -eq 0 ]
}

@test "Check job details for output location" {
  # Submit job if not already done
  job_id=$(get_job_id_by_name "basic-test")
  if [ -z "$job_id" ]; then
    run ssh $CONTROLLER "cd $TEST_DIR && sbatch basic_test.sh"
    [ "$status" -eq 0 ]
    job_id=$(echo "$output" | awk '{print $4}')
  fi

  # Check job details
  run ssh $CONTROLLER "scontrol show job $job_id | grep StdOut"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "StdOut" ]]
}

@test "Find job output" {
  run ssh $CONTROLLER "find $TEST_DIR -name \"basic-test*.out\" -exec cat {} \\; 2>/dev/null || echo \"No output file found\""
  [ "$status" -eq 0 ]
  [[ ! "$output" =~ "No output file found" ]]
  [[ "$output" =~ "Basic test completed successfully" ]]
}

@test "Submit test job with direct output" {
  run ssh $CONTROLLER "cd $TEST_DIR && sbatch --output=/dev/stdout --wrap=\"hostname; date; echo Testing direct output\" | tee $TEST_DIR/direct_output.txt"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Submitted batch job" ]]
}

@test "Check slurm user permissions" {
  run ssh $CONTROLLER "ls -la /var/log/slurm/ /var/spool/slurm"
  [ "$status" -eq 0 ]
}

@test "Test file creation as slurm user" {
  run ssh $CONTROLLER "sudo -u slurm touch $TEST_DIR/slurm_test_file && ls -la $TEST_DIR/slurm_test_file"
  [ "$status" -eq 0 ]
}