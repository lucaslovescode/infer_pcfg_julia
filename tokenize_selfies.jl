
using PyCall
include("PCFG.jl")
"""
Read SELFIES strings from a file and convert to integer tokens
"""
function read_selfies(filename::String)
    # Read SELFIES strings from file (one per line)
    selfies_strings = readlines(filename)
    
    # Build vocabulary from all SELFIES tokens
    vocab = build_selfies_vocab(selfies_strings)
    
    # Convert SELFIES strings to integer sequences
    sentences = [selfies_to_tokens(s, vocab) for s in selfies_strings]
    
    # Create train/test split (90/10)
    te = collect(1:length(sentences)).%10 .== 0
    data_te = sentences[te]
    data_tr = sentences[te .== false]
    

    @show length(data_te) length(data_tr)
    @show length(vocab)

    
    data_tr, data_te, vocab
end

"""
Build vocabulary mapping SELFIES tokens to integer IDs
"""
function build_selfies_vocab(selfies_strings::Vector{String})
    vocab = Dict{String, ta}()
    vocab["<PAD>"] = ta(0)  # Reserve 0 for padding
    
    token_id = ta(1)
    
    for selfies_str in selfies_strings
        tokens = tokenize_selfies(selfies_str)
        for token in tokens
            if !haskey(vocab, token)
                vocab[token] = token_id
                token_id += 1
            end
        end
    end
    
    return vocab
end

"""
Tokenize a SELFIES string into individual tokens
SELFIES format: [token1][token2][token3]...
"""
function tokenize_selfies(selfies_str::String)
    tokens = String[]
    i = 1
    while i <= length(selfies_str)
        if selfies_str[i] == '['
            # Find closing bracket
            j = i + 1
            while j <= length(selfies_str) && selfies_str[j] != ']'
                j += 1
            end
            if j <= length(selfies_str)
                push!(tokens, selfies_str[i:j])  # Include brackets
                i = j + 1
            else
                i += 1  # Skip malformed token
            end
        else
            i += 1  # Skip unexpected characters
        end
    end
    return tokens
end

"""
Convert SELFIES string to sequence of integer tokens
"""
function selfies_to_tokens(selfies_str::String, vocab::Dict{String, ta})
    tokens = tokenize_selfies(selfies_str)
    return [vocab[token] for token in tokens if haskey(vocab, token)]
end

"""
Convert sequence of integer tokens back to SELFIES string
"""
function tokens_to_selfies(tokens::Vector{ta}, vocab::Dict{String, ta})
    # Create reverse vocabulary
    rev_vocab = Dict(v => k for (k, v) in vocab)
    
    # Convert tokens to SELFIES
    selfies_tokens = [rev_vocab[t] for t in tokens if haskey(rev_vocab, t)]
    return join(selfies_tokens, "")
end

"""
If you have SMILES strings instead, you can convert them to SELFIES
Note: Requires the 'selfies' Python package
You can call Python from Julia using PyCall.jl
"""
function smiles_file_to_selfies_file(input_smiles_file::String, 
                                      output_selfies_file::String)
    
    selfies = pyimport("selfies")
    
    smiles_strings = readlines(input_smiles_file)
    
    open(output_selfies_file, "w") do f
        for smiles in smiles_strings
            try
                selfies_str = selfies.encoder(smiles)
                println(f, selfies_str)
            catch e
                println("Error converting: $smiles")
            end
        end
    end
end