include("experiments.jl")
include("tokenize_selfies.jl")

using JLD

selfies_to_tokens("training.txt","selfies_training")
main_train(Bag_block, "/home/lucas/OneDrive/Documents/phd1/infer_pcfg_julia") 