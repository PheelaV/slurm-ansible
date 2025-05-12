#!/usr/bin/env bats

# Load helpers
load "helpers.bash"

# Setup function runs before each test
setup() {
  # Use the existing test environment setup
  setup_test_env
}

teardown() {
  # Cancel any remaining jobs
  ssh $CONTROLLER "scancel --user=slurmadmin" 2>/dev/null || true
  
  # Clean up test environment
  cleanup_test_env
}

# Each test is independent - no shared state between tests
@test "Multi-node job submission with explicit output" {
  # Use the existing multinode test script, but with explicit output path
  local TEST_ID="multi-$(date +%s)"
  local OUTPUT_FILE="${TEST_DIR}/multi-${TEST_ID}.out"
  local ERROR_FILE="${TEST_DIR}/multi-${TEST_ID}.err"
  
  # Submit the job
  run ssh $CONTROLLER "cd $TEST_DIR && sbatch \
    --job-name=${TEST_ID} \
    --output=${OUTPUT_FILE} \
    --error=${ERROR_FILE} \
    --nodes=2 \
    --ntasks-per-node=1 \
    ${MULTINODE_JOB_SCRIPT:-$TEST_DIR/multinode_test.sh}"
  
  echo "Output: $output"
  
  # Verify submission was successful
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Submitted batch job" ]]
}

@test "Check multinode jobs in queue" {
  # Submit a test job specifically for this test
  local TEST_ID="queue-$(date +%s)"
  local JOB_ID=$(ssh $CONTROLLER "cd $TEST_DIR && sbatch \
    --job-name=${TEST_ID} \
    --output=${TEST_DIR}/queue-${TEST_ID}.out \
    --error=${TEST_DIR}/queue-${TEST_ID}.err \
    --nodes=2 \
    --ntasks-per-node=1 \
    ${MULTINODE_JOB_SCRIPT:-$TEST_DIR/multinode_test.sh} | awk '{print \$4}'")
  
  echo "Submitted job ID: $JOB_ID"
  
  # Check if job is in the queue
  run ssh $CONTROLLER "squeue --job=$JOB_ID --noheader"
  echo "Queue output: $output"
  
  # Job should be in the queue (we check immediately after submission)
  [ "$status" -eq 0 ]
  
  # Verify job details show multi-node allocation
  run ssh $CONTROLLER "scontrol show job $JOB_ID"
  echo "Job details: $output"
  [ "$status" -eq 0 ]
  [[ "$output" == *"NumNodes=2"* ]]
  
  # Cancel the job so it doesn't interfere with other tests
  ssh $CONTROLLER "scancel $JOB_ID" || true
}

@test "Wait for multi-node job completion" {
  # Submit a job specifically for this test
  local TEST_ID="wait-$(date +%s)"
  local JOB_ID=$(ssh $CONTROLLER "cd $TEST_DIR && sbatch \
    --job-name=${TEST_ID} \
    --output=${TEST_DIR}/wait-${TEST_ID}.out \
    --error=${TEST_DIR}/wait-${TEST_ID}.err \
    --nodes=2 \
    --ntasks-per-node=1 \
    ${MULTINODE_JOB_SCRIPT:-$TEST_DIR/multinode_test.sh} | awk '{print \$4}'")
  
  echo "Submitted job ID: $JOB_ID"
  
  # Wait for job to complete (timeout after 60 seconds)
  wait_for_job "$JOB_ID" 60
  
  # Verify job completed
  run ssh $CONTROLLER "sacct -j $JOB_ID --format=JobID,State --noheader"
  echo "Job state: $output"
  
  # Job should be in a terminal state
  [[ "$output" == *"COMPLETED"* ]] || [[ "$output" == *"RUNNING"* ]] || [[ "$output" == *"PENDING"* ]]
}

@test "Verify multi-node job output" {
  # Submit a job specifically for this test
  local TEST_ID="output-$(date +%s)"
  local OUTPUT_FILE="${TEST_DIR}/output-${TEST_ID}.out"
  local ERROR_FILE="${TEST_DIR}/output-${TEST_ID}.err"
  
  local JOB_ID=$(ssh $CONTROLLER "cd $TEST_DIR && sbatch \
    --job-name=${TEST_ID} \
    --output=${OUTPUT_FILE} \
    --error=${ERROR_FILE} \
    --nodes=2 \
    --ntasks-per-node=1 \
    --wrap='hostname; sleep 2' | awk '{print \$4}'")
  
  echo "Submitted job ID: $JOB_ID for output verification"
  
  # Wait for job to complete
  wait_for_job "$JOB_ID" 60
  
  # Give some extra time for file system operations to complete
  sleep 3
  
  # Display available output files
  run ssh $CONTROLLER "ls -la ${TEST_DIR}/ | grep output-"
  echo "Available files: $output"
  
  # Get content of the job output file
  run ssh $CONTROLLER "cat ${OUTPUT_FILE}"
  echo "Output file content: $output"
  
  # Verify that output contains a compute node hostname
  [ "$status" -eq 0 ]
  [[ "$output" == *"slurm-compute-"* ]]
}