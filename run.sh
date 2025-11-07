#!/bin/bash
#SBATCH --job-name=pcfg
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=128G
#SBATCH --time=08:00:00
#SBATCH --partition=amilan
#SBATCH --qos=normal
#SBATCH --account=ucb736_asc1
#SBATCH --output=slurm-%j.out

set -euo pipefail

# --- Environment setup ---
module purge
module load julia/1.8.1

export JULIA_NUM_THREADS=${SLURM_CPUS_PER_TASK:-1}
export JULIA_PROJECT="${SLURM_SUBMIT_DIR}"

# --- Define a safe run directory ---
# Prefer SLURM_TMPDIR if available; otherwise use scratch (not submit dir)
BASE_RUN_DIR="${SLURM_TMPDIR:-${RC_SCRATCH:-/tmp}}"
RUNDIR="${BASE_RUN_DIR}/pcfg_${SLURM_JOB_ID}"
mkdir -p "$RUNDIR"

# --- Copy input files safely ---
# Exclude output folders and SLURM logs to avoid recursion or clutter
rsync -a --delete \
  --exclude 'out/' \
  --exclude 'slurm-*.out' \
  "${SLURM_SUBMIT_DIR}/" "$RUNDIR/"

cd "$RUNDIR"

# --- Define data/output directories ---
export DATA_DIR="${RUNDIR}/data"
export OUT_DIR="${RUNDIR}/out"
mkdir -p "$OUT_DIR"

# --- Run Julia job ---
julia --color=yes slurm.jl

# --- Copy results back safely ---
mkdir -p "${SLURM_SUBMIT_DIR}/out"
rsync -a "${OUT_DIR}/" "${SLURM_SUBMIT_DIR}/out/"

echo "Done. Outputs synced to: ${SLURM_SUBMIT_DIR}/out"

# --- Optional cleanup (uncomment if desired) ---
# rm -rf "$RUNDIR"
