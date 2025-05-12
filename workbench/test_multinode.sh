# Create a multi-node test job
cat > multinode.sh << 'EOF'
#!/bin/bash
#SBATCH --job-name=multinode
#SBATCH --output=multinode-%j.out
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1

srun hostname
echo "Job ran on multiple nodes"
EOF

# Submit the job
sbatch multinode.sh

# Check the output file after job completes
cat multinode-*.out