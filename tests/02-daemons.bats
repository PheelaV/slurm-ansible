#!/usr/bin/env bats

# Load helpers
load "helpers.bash"

@test "Controller daemon status" {
  run ssh $CONTROLLER "systemctl is-active slurmctld"
  [ "$status" -eq 0 ]
  [ "$output" = "active" ]
}

@test "Database daemon status" {
  run ssh $CONTROLLER "systemctl is-active slurmdbd"
  [ "$status" -eq 0 ]
  [ "$output" = "active" ]
}

@test "Compute-1 daemon status" {
  run ssh ${COMPUTE_NODES[0]} "systemctl is-active slurmd"
  [ "$status" -eq 0 ]
  [ "$output" = "active" ]
}

@test "Compute-2 daemon status" {
  run ssh ${COMPUTE_NODES[1]} "systemctl is-active slurmd"
  [ "$status" -eq 0 ]
  [ "$output" = "active" ]
}

@test "Munge authentication to compute-1" {
  run bash -c "ssh $CONTROLLER 'munge -n' | ssh ${COMPUTE_NODES[0]} 'unmunge' | grep STATUS"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Success" ]]
}

@test "Munge authentication to compute-2" {
  run bash -c "ssh $CONTROLLER 'munge -n' | ssh ${COMPUTE_NODES[1]} 'unmunge' | grep STATUS"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Success" ]]
}

@test "Cluster state" {
  run ssh $CONTROLLER "sinfo"
  [ "$status" -eq 0 ]
}

@test "Node state" {
  run ssh $CONTROLLER "scontrol show nodes | grep State"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "IDLE" ]] || [[ "$output" =~ "ALLOCATED" ]]
}

@test "Partition state" {
  run ssh $CONTROLLER "scontrol show partition"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "State=UP" ]]
}
