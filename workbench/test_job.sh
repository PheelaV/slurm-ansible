# Create a test job script on the controller
cat > testjob.sh << 'EOF'
#!/bin/bash
#SBATCH --job-name=test
#SBATCH --output=test-%j.out
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1

echo "Hello from $(hostname)"
sleep 10
echo "Current date and time: $(date)"
echo "Job completed successfully"
EOF

# Make it executable
chmod +x testjob.sh

# Submit the job
sbatch testjob.sh

# Check job status
squeue