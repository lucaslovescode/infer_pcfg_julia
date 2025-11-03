include("PCFG_all.jl")
include("slice_sampling.jl")
include("block_sampling_all.jl")
include("hyper_parameters.jl")
include("tokenize_selfies.jl")
include("experiments.jl")

using JLD

# Load the model
c, bags_tr, logging, vocab = load_model("./output/block-10.09-14:59/model-720.jld", Bag_block)

rev_vocab = Dict(v => k for (k, v) in vocab)

# Collect all nonterminals and terminals
nonterminals = Set{Int}()
terminals = Set{Int}()

# Collect from binary rules
for (encoded_rule, bins) in c.t2.rule.bins_dic
    count = sum(bins)
    if count > 0
        w2, w1, A, B, C = decode_t2(encoded_rule)
        push!(nonterminals, A, B, C)
    end
end

# Collect from terminal rules
for (encoded_rule, bins) in c.t0.t0_rule.bins_dic
    count = sum(bins)
    if count > 0
        w2, w1, A, u = decode_t0(encoded_rule)
        push!(nonterminals, A)
        push!(terminals, u)
    end
end

open("pcfg_rules.txt", "w") do f
    println(f, "NONTERMINALS")
    for nt in sort(collect(nonterminals))
        println(f, "NT_$nt")
    end
    
    println(f, "\nTERMINALS")
    for term in sort(collect(terminals))
        terminal_str = get(rev_vocab, term, "UNKNOWN_$term")
        println(f, "$terminal_str")
    end

    println(f, "\nBINARY RULES")
    for (encoded_rule, bins) in sort(collect(c.t2.rule.bins_dic))
        count = sum(bins)
        if count > 0
            w2, w1, A, B, C = decode_t2(encoded_rule)
            w2_str = w2 == PAD ? "PAD" : get(rev_vocab, w2, "UNK_$w2")
            w1_str = w1 == PAD ? "PAD" : get(rev_vocab, w1, "UNK_$w1")
            println(f, "NT_$A, NT_$B, NT_$C  $count")
        end
    end
    
    println(f, "\nTERMINAL RULES")
    for (encoded_rule, bins) in sort(collect(c.t0.t0_rule.bins_dic))
        count = sum(bins)
        if count > 0
            w2, w1, A, u = decode_t0(encoded_rule)
            w2_str = w2 == PAD ? "PAD" : get(rev_vocab, w2, "UNK_$w2")
            w1_str = w1 == PAD ? "PAD" : get(rev_vocab, w1, "UNK_$w1")
            terminal = get(rev_vocab, u, "UNKNOWN_$u")
            println(f, "NT_$A $terminal, $terminal $count")
        end
    end
end

println("Rules saved to pcfg_rules.txt")