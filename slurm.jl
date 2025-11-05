const ROOT = abspath(@__DIR__)
include(joinpath(ROOT, "experiments.jl"))
include(joinpath(ROOT, "tokenize_selfies.jl"))

using JLD
using Dates

const DATA_DIR = get(ENV, "DATA_DIR", joinpath(ROOT, "data"))
const _scratch = get(ENV, "SLURM_TMPDIR", get(ENV, "RC_SCRATCH", joinpath(ROOT, "out")))
const OUT_DIR  = get(ENV, "OUT_DIR", joinpath(_scratch, "pcfg_run_" * string(getpid())))
isdir(OUT_DIR) || mkpath(OUT_DIR)

const TRAIN_FILE = get(ENV, "TRAIN_FILE", joinpath(DATA_DIR, "training.txt"))
const TOK_BASENAME = get(ENV, "TOK_BASENAME", "selfies_training")

selfies_to_tokens(TRAIN_FILE, joinpath(OUT_DIR, TOK_BASENAME))
main_train(Bag_block, ROOT)

open(joinpath(OUT_DIR, "run_manifest.txt"), "w") do io
    println(io, "ROOT      = $ROOT")
    println(io, "DATA_DIR  = $DATA_DIR")
    println(io, "OUT_DIR   = $OUT_DIR")
    println(io, "TRAIN_FILE= $TRAIN_FILE")
    println(io, "DATE      = $(Dates.now())")
    println(io, "JULIA     = $(VERSION)")
end 