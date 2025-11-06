#!/bin/bash
#SBATCH --job-name=pcfg
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=128G
#SBATCH --time=08:00:00
#SBATCH --account=YOUR_ALLOC_HERE
#SBATCH --output=slurm-%j.out

set -euo pipefail
module purge
module load julia/1.8.1

export JULIA_NUM_THREADS=${SLURM_CPUS_PER_TASK:-1}
export JULIA_PROJECT=${SLURM_SUBMIT_DIR}

RUNDIR="${SLURM_TMPDIR:-${RC_SCRATCH:-$SLURM_SUBMIT_DIR}}/pcfg_${SLURM_JOB_ID}"
mkdir -p "$RUNDIR"
rsync -a --delete "${SLURM_SUBMIT_DIR}/" "$RUNDIR/"
cd "$RUNDIR"

export DATA_DIR="${RUNDIR}/data"
export OUT_DIR="${RUNDIR}/out"
mkdir -p "$OUT_DIR"

julia --color=yes Slurm.jl

mkdir -p "${SLURM_SUBMIT_DIR}/out"
rsync -a "${OUT_DIR}/" "${SLURM_SUBMIT_DIR}/out/"
echo "Done. Outputs synced to: ${SLURM_SUBMIT_DIR}/out"
