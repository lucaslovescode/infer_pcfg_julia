include("PCFG_all.jl")
include("slice_sampling.jl")
include("block_sampling_all.jl")
include("hyper_parameters.jl")
include("tokenize_selfies.jl")
include("sampling.jl")

#using BenchmarkTools
using Random
using JLD
using DelimitedFiles
using Dates
using Statistics

###################################################################################
# 初期化，テスト，訓練，ハイパーパラメータの表示，保存
###################################################################################

function init(sentences,vocab_size)
    initial_V = [cha(EX+1)]  # Create the vector properly
    c = PCFG_all(vocab_size, initial_V)
    bags_init = [ Bag_block(smp) for smp in sentences ]
    for bag in bags_init
        resample(bag, c)
        add_sampled_new(bag, c)
    end
    @show _N(c)
    c, bags_init
end

function test(c::PCFG_all, bags_te::Vector{Bag_block}, logging)
    ps_top = [get_p_top(bag, c) for bag in bags_te]
    score = mean(log.(ps_top))
    time_str = Dates.format(now(), "mm/dd-HH:MM:SS")
    push!(logging, [time_str, _N(c), score])
    println(time_str, " " , _N(c), " ", score  )
end

function train(c::PCFG_all, bags::Vector{T}) where T<:Bag
    for (j, bag) in enumerate(bags)
        #@show bag.sampled_type2 bag.sampled_type0 c.V _N(c)
        del_sampled(bag, c)
        resample(bag, c)
        add_sampled(bag, c)
    end
end

function show_hyper(c::PCFG_all)
    for lay in get_all_layers(c)
        if typeof(lay) <: PYPLayer
            @show lay.θ, lay.d
        end
    end
end

function save_model(output_dirname, i, 
        c::PCFG_all, bags_tr::Vector{T}, logging::Vector{T2}, vocab::Dict{String, ta}) where {T<:Bag, T2}
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

    open("$output_dirname/pcfg_rules-$i.txt", "w") do f
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

println("Rules saved to pcfg_rules-$i.txt")
end

function load_model(output_file_name, T)
    obj = load(output_file_name)
    c = obj["pcfg"]
    #@show obj["rules"]
    bags_tr = (x->T(x)).(obj["rules"])
    vocab = obj["vocab"]
    c, bags_tr, obj["logging"], vocab
end

function read_brown()
    sentences = [split(l) for l in readlines("brown16.txt")][3:1000]
    sentences = [ [ta(parse(ta, a)+1) for a in l] for l in sentences ]
    te = collect(1:length(sentences)).%10 .== 0
    data_te = sentences[te]
    data_tr = sentences[te .== false]
    @show length(data_te) length(data_tr)
    data_tr, data_te
end    

###################################################################################
# データを読み込み，学習を行う．
###################################################################################
function main_train(T, output_dirname)
    mkpath(output_dirname)
    
    data_tr, data_te, vocab = read_selfies("/selfies_training.txt")
    
    #sentences = [[1,2,3,4,1,2], [1,2,3,4,1,2,1,2], [3,4,3,4,3,4], [1,2,3,4,1,2]]
    #sentences = [ [ta(a) for a in l] for l in sentences ]

    Random.seed!(0)

    logging = []

    #初期化
    c, bags_init = init(data_tr,length(vocab))
    #訓練用バッグ
    bags_tr = [ T(BagSave(bag)) for bag in bags_init ]
    #テスト用バッグ
    bags_te = [ Bag_block(smp) for smp in data_te ]

    update_V(c)
    test(c, bags_te, logging)
    save_model(output_dirname, 0, c, bags_tr, logging,vocab)
    for i in 1:3000
        Base.invokelatest(mcmc_hyperparam, c)
        train(c, bags_tr)
        if i%100==0
            test(c, bags_te, logging)
            save_model(output_dirname, i, c, bags_tr, logging,vocab)
        end
    end
end

###################################################################################
# メインパート の切り替え：学習とログの確認
###################################################################################
if length(ARGS)>=2 && ARGS[1] == "train" && ARGS[2] == "block"

    output_dirname =  "./output/block"*Dates.format(now(), "-mm.dd-HH:MM/")
    main_train(Bag_block, output_dirname)

elseif length(ARGS)>=2 && ARGS[1] == "train" && ARGS[2] == "slice"

    output_dirname =  "./output/slice"*Dates.format(now(), "-mm.dd-HH:MM/")
    main_train(Bag_slice, output_dirname)

elseif length(ARGS)>=2 && ARGS[1] == "readlog" 

    output_file_name = ARGS[2]
    c, bags_tr, logging = load_model(output_file_name)
    println("last logging:",  logging[end])
    data_tr, data_te = read_brown()
    bags_te = [ Bag_block(smp) for smp in data_te ]
    test(c, bags_te, logging)

elseif length(ARGS)>=2 && ARGS[1] == "resume" 

    output_file_name = ARGS[2]
    c, bags_tr, logging = load_model(output_file_name, Bag_block)
    println("last logging:",  logging[end])
    output_dirname =  "./output/slice"*Dates.format(now(), "-mm.dd-HH:MM/")
    mkpath(output_dirname)
    data_tr, data_te = read_brown()
    Random.seed!(0)
    logging = []
    bags_te = [ Bag_block(smp) for smp in data_te ]
    #test(c, bags_te, logging)
    save_model(output_dirname, 0, c, bags_te, logging)
    for i in 1:100
        mcmc_hyperparam(c)
        train(c, bags_tr)
        if i%10==0
            test(c, bags_te, logging)
            save_model(output_dirname, i, c, bags_te, logging)
        end
    end
end


#check_consistency(c)
#check_probsum(c)
