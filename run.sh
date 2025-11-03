#!/bin/bash

# Copy/paste this job script into a text file and submit with the command:
#    sbatch thefilename
# Job standard output will go to the file slurm-%j.out (where %j is the job ID)

#SBATCH --nodes=1   # Number of nodes to use
#SBATCH --ntasks-per-node=8   # Use 8 processor cores per node 
#SBATCH --time=0-8:0:0   # Walltime limit (DD-HH:MM:SS)
#SBATCH --mem=128G   # Maximum memory per node
#SBATCH --acount=luwh8285@colorado.edu   # Slurm account to use for the job

# LOAD MODULES, INSERT CODE, AND RUN YOUR PROGRAMS HERE
module purge
module load julia/1.8.5

srun julia slurm.jl