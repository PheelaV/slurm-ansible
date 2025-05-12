#!/usr/bin/env bats

# Load helpers
load "helpers.bash"

@test "Verify accounting records" {
  run ssh $CONTROLLER "sacct -X --format=JobID,JobName,State,ExitCode,Submit,Start,End,Elapsed,MaxVMSize"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "COMPLETED" ]]
}

@test "Verify user fair-share" {
  run ssh $CONTROLLER "sshare -a"
  [ "$status" -eq 0 ]
}

# @test "Verify accounting includes recent jobs" {
#   # Get current time minus 1 hour to ensure we capture recent jobs
#   start_time=$(date -d '1 hour ago' +'%Y-%m-%dT%H:%M:%S')
  
#   # Check accounting records from the last hour
#   run ssh $CONTROLLER "sacct -X -S $start_time --format=JobID,JobName,State"
#   [ "$status" -eq 0 ]
#   [[ "$output" =~ "COMPLETED" ]]
# }

# @test "Verify job efficiency reporting" {
#   # Check if seff command is available
#   run ssh $CONTROLLER "command -v seff"
#   if [ "$status" -ne 0 ]; then
#     skip "seff command not available"
#   fi
  
#   # Get most recent job ID
#   run ssh $CONTROLLER "sacct -X -n -o jobid | head -1"
#   [ "$status" -eq 0 ]
#   job_id=$(echo "$output" | awk '{print $1}')
  
#   if [ -z "$job_id" ]; then
#     skip "No recent jobs found"
#   fi
  
#   # Run seff on the job
#   run ssh $CONTROLLER "seff $job_id"
#   [ "$status" -eq 0 ]
# }
