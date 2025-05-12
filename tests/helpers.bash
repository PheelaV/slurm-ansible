#!/bin/bash
# Helper functions for Slurm tests

# Load configuration
# Use BATS_TEST_DIRNAME which is set by BATS when running tests
CONFIG_PATH="${BATS_TEST_DIRNAME:-$(dirname "$0")}/config.sh"
load "${BATS_TEST_DIRNAME:-$(dirname "$0")}/config.sh"

# Setup test environment
setup_test_env() {
  # Create test directory on controller 
  # (should already exist on shared storage, but just in case)
  ssh $CONTROLLER "mkdir -p $TEST_DIR"
  ssh $CONTROLLER "chmod 777 $TEST_DIR"
  
  # Create test scripts if they don't exist
  create_test_scripts
}

# Create test job scripts
create_test_scripts() {
  # Basic job test script
  cat > /tmp/basic_test.sh << EOF
#!/bin/bash
#SBATCH --job-name=basic-test
#SBATCH --output=$TEST_DIR/%x-%j.out
#SBATCH --nodes=1
#SBATCH --ntasks=1

echo "Running on host: \$(hostname)"
echo "Date and time: \$(date)"
echo "Working directory: \$(pwd)"
echo "Current user: \$(whoami)"
echo "Basic test completed successfully"
EOF

  # Multi-node job test script
  cat > /tmp/multinode_test.sh << EOF
#!/bin/bash
#SBATCH --job-name=multinode-test
#SBATCH --output=$TEST_DIR/%x-%j.out
#SBATCH --nodes=2
#SBATCH --ntasks=2

echo "Job started at: \$(date)"
echo "Running on multiple nodes:"
srun hostname
echo "Multi-node test completed successfully"
EOF

  # Resource test script
  cat > /tmp/resource_test.sh << EOF
#!/bin/bash
#SBATCH --job-name=resource-test
#SBATCH --output=$TEST_DIR/%x-%j.out
#SBATCH --nodes=1
#SBATCH --mem=256M
#SBATCH --cpus-per-task=1

echo "Memory allocated: \$SLURM_MEM_PER_NODE MB"
echo "CPUs allocated: \$SLURM_CPUS_PER_TASK"
free -m
nproc
echo "Resource test completed successfully"
EOF

  # Copy test scripts to controller
  scp /tmp/basic_test.sh /tmp/multinode_test.sh /tmp/resource_test.sh $CONTROLLER:$TEST_DIR/
  ssh $CONTROLLER "chmod +x $TEST_DIR/*.sh"
}

# Clean up test environment
cleanup_test_env() {
  ssh $CONTROLLER "find $TEST_DIR -name \"*test*.out\" -exec cat {} \\; 2>/dev/null; rm -f $TEST_DIR/*test*.out $TEST_DIR/slurm_test_file" || true
  return 0  # Always return success, matching original script behavior
}

# Wait for job to complete
wait_for_job() {
  local job_id=$1
  local timeout=${2:-30}
  local elapsed=0
  
  while [[ $elapsed -lt $timeout ]]; do
    if ! ssh $CONTROLLER "squeue -j $job_id -h" | grep -q "$job_id"; then
      # Job not in queue anymore, so it completed
      return 0
    fi
    sleep 2
    elapsed=$((elapsed + 2))
  done
  
  # Timed out waiting for job
  return 1
}

# Get job ID from queue by name
get_job_id_by_name() {
  local job_name=$1
  ssh $CONTROLLER "squeue -h -n $job_name -o %i" 2>/dev/null || echo ""
}

# Get the output file for a job
get_job_output_file() {
  local job_id=$1
  ssh $CONTROLLER "scontrol show job $job_id | grep StdOut | awk '{print \$3}' | cut -d= -f2"
}
# #!/bin/bash
# # Helper functions for Slurm tests

# # Load configuration
# load "config.sh"

# # Setup test environment
# setup_test_env() {
#   # Create test directory on controller
#   ssh $CONTROLLER "mkdir -p $TEST_DIR"
#   ssh $CONTROLLER "chmod 777 $TEST_DIR"

#   # Create test scripts if they don't exist
#   create_test_scripts
# }

# # Create test job scripts
# create_test_scripts() {
#   # Basic job test script
#   cat >/tmp/basic_test.sh <<EOF
# #!/bin/bash
# #SBATCH --job-name=basic-test
# #SBATCH --output=$TEST_DIR/%x-%j.out
# #SBATCH --nodes=1
# #SBATCH --ntasks=1

# echo "Running on host: \$(hostname)"
# echo "Date and time: \$(date)"
# echo "Working directory: \$(pwd)"
# echo "Current user: \$(whoami)"
# echo "Basic test completed successfully"
# EOF

#   # Multi-node job test script
#   cat >/tmp/multinode_test.sh <<EOF
# #!/bin/bash
# #SBATCH --job-name=multinode-test
# #SBATCH --output=$TEST_DIR/%x-%j.out
# #SBATCH --nodes=2
# #SBATCH --ntasks=2

# echo "Job started at: \$(date)"
# echo "Running on multiple nodes:"
# srun hostname
# echo "Multi-node test completed successfully"
# EOF

#   # Resource test script
#   cat >/tmp/resource_test.sh <<EOF
# #!/bin/bash
# #SBATCH --job-name=resource-test
# #SBATCH --output=$TEST_DIR/%x-%j.out
# #SBATCH --nodes=1
# #SBATCH --mem=256M
# #SBATCH --cpus-per-task=1

# echo "Memory allocated: \$SLURM_MEM_PER_NODE MB"
# echo "CPUs allocated: \$SLURM_CPUS_PER_TASK"
# free -m
# nproc
# echo "Resource test completed successfully"
# EOF

#   # Copy test scripts to controller
#   scp /tmp/basic_test.sh /tmp/multinode_test.sh /tmp/resource_test.sh $CONTROLLER:$TEST_DIR/
#   ssh $CONTROLLER "chmod +x $TEST_DIR/*.sh"
# }

# # Clean up test environment
# cleanup_test_env() {
#   ssh $CONTROLLER "find / -name \"*test*.out\" -exec cat {} \\; 2>/dev/null; rm -rf $TEST_DIR" || true
#   return 0 # Always return success, matching original script behavior
# }

# # Wait for job to complete
# wait_for_job() {
#   local job_id=$1
#   local timeout=${2:-30}
#   local elapsed=0

#   while [[ $elapsed -lt $timeout ]]; do
#     if ! ssh $CONTROLLER "squeue -j $job_id -h" | grep -q "$job_id"; then
#       # Job not in queue anymore, so it completed
#       return 0
#     fi
#     sleep 2
#     elapsed=$((elapsed + 2))
#   done

#   # Timed out waiting for job
#   return 1
# }

# # Get job ID from queue by name
# get_job_id_by_name() {
#   local job_name=$1
#   ssh $CONTROLLER "squeue -h -n $job_name -o %i" 2>/dev/null || echo ""
# }

# # Get the output file for a job
# get_job_output_file() {
#   local job_id=$1
#   ssh $CONTROLLER "scontrol show job $job_id | grep StdOut | awk '{print \$3}' | cut -d= -f2"
# }
# # #!/bin/bash
# # # Helper functions for Slurm tests

# # # Load configuration
# # load "config.sh"

# # # Setup test environment
# # setup_test_env() {
# #   # Create test directory on controller
# #   ssh $CONTROLLER "mkdir -p $TEST_DIR"
# #   ssh $CONTROLLER "chmod 777 $TEST_DIR"

# #   # Create test scripts if they don't exist
# #   create_test_scripts
# # }

# # # Create test job scripts
# # create_test_scripts() {
# #   # Basic job test script
# #   cat > /tmp/basic_test.sh << 'EOF'
# # #!/bin/bash
# # #SBATCH --job-name=basic-test
# # #SBATCH --output=%x-%j.out
# # #SBATCH --nodes=1
# # #SBATCH --ntasks=1

# # echo "Running on host: $(hostname)"
# # echo "Date and time: $(date)"
# # echo "Working directory: $(pwd)"
# # echo "Current user: $(whoami)"
# # echo "Basic test completed successfully"
# # EOF

# #   # Multi-node job test script
# #   cat > /tmp/multinode_test.sh << 'EOF'
# # #!/bin/bash
# # #SBATCH --job-name=multinode-test
# # #SBATCH --output=%x-%j.out
# # #SBATCH --nodes=2
# # #SBATCH --ntasks=2

# # echo "Job started at: $(date)"
# # echo "Running on multiple nodes:"
# # srun hostname
# # echo "Multi-node test completed successfully"
# # EOF

# #   # Resource test script
# #   cat > /tmp/resource_test.sh << 'EOF'
# # #!/bin/bash
# # #SBATCH --job-name=resource-test
# # #SBATCH --output=%x-%j.out
# # #SBATCH --nodes=1
# # #SBATCH --mem=256M
# # #SBATCH --cpus-per-task=1

# # echo "Memory allocated: $SLURM_MEM_PER_NODE MB"
# # echo "CPUs allocated: $SLURM_CPUS_PER_TASK"
# # free -m
# # nproc
# # echo "Resource test completed successfully"
# # EOF

# #   # Copy test scripts to controller
# #   scp /tmp/basic_test.sh /tmp/multinode_test.sh /tmp/resource_test.sh $CONTROLLER:$TEST_DIR/
# #   ssh $CONTROLLER "chmod +x $TEST_DIR/*.sh"
# # }

# # # Clean up test environment
# # cleanup_test_env() {
# #   ssh $CONTROLLER "rm -rf $TEST_DIR" || true
# # }
# # # cleanup_test_env() {
# # #   ssh $CONTROLLER "find / -name \"*test*.out\" -exec cat {} \\; 2>/dev/null; rm -rf $TEST_DIR" || true
# # # }

# # # Wait for job to complete
# # wait_for_job() {
# #   local job_id=$1
# #   local timeout=${2:-30}
# #   local elapsed=0

# #   while [[ $elapsed -lt $timeout ]]; do
# #     if ! ssh $CONTROLLER "squeue -j $job_id -h" | grep -q "$job_id"; then
# #       # Job not in queue anymore, so it completed
# #       return 0
# #     fi
# #     sleep 2
# #     elapsed=$((elapsed + 2))
# #   done

# #   # Timed out waiting for job
# #   return 1
# # }

# # # Get job ID from queue by name
# # get_job_id_by_name() {
# #   local job_name=$1
# #   ssh $CONTROLLER "squeue -h -n $job_name -o %i" 2>/dev/null || echo ""
# # }

# # # Get the output file for a job
# # get_job_output_file() {
# #   local job_id=$1
# #   ssh $CONTROLLER "scontrol show job $job_id | grep StdOut | awk '{print \$3}' | cut -d= -f2"
# # }
