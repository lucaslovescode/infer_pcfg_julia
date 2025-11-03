###################################################################################
# PCFGの抽象タイプ・共通の定義，関数
###################################################################################
abstract type PCFG end

include("pyp.jl")

const cha = UInt8   # 非終端記号の型
const ta  = UInt16  # 終端記号(アルファベット)の型
const LEN_CHA = 8   # cha のビット数
const LEN_TA = 10   # ta  のビット数
const enc = UInt64  # ルールのエンコードの型
const MSK_CHA = (enc(1)<<LEN_CHA - 1 ) # cha のビット数だけ 1 を立てたマスク
const MSK_TA  = (enc(1)<<LEN_TA  - 1 ) # ta  のビット数だけ 1 を立てたマスク

const NMAX  = 127*2 #非終端記号の最大数
const ST    = cha(1) #1がスタートシンボル
const ST_ID =  2 # CYK table 中の id (何番目に大きいシンボルか？)

const PAD    = ta(0)     # 0    が padding のための非終端記号

@inline encode(w2::ta, w1::ta, A::cha, B::cha, C::cha) = (enc(B)<<LEN_CHA + C, 
                                                enc(w2)<<(LEN_TA + LEN_CHA) + enc(w1)<<LEN_CHA + A)
@inline encode(w2::ta, w1::ta, A::cha, u::ta         ) =  (enc(u), 
     enc(w2)<<(LEN_TA + LEN_CHA) + enc(w1)<<LEN_CHA + A)
join_xy(etup::Tuple{enc,enc}) = etup[1] + etup[2] << 2LEN_CHA 
decode_t2(e::enc) = ( 
    ta((e>>(2*LEN_CHA + LEN_CHA + LEN_TA))&MSK_TA),  # w2: shift by 16+8+10=34
    ta((e>>(2*LEN_CHA + LEN_CHA))&MSK_TA),           # w1: shift by 16+8=24
    cha((e>>(2*LEN_CHA))&MSK_CHA),                   # A:  shift by 16
    cha((e>>LEN_CHA)&MSK_CHA),                       # B:  shift by 8
    cha((e)&MSK_CHA)                                 # C:  shift by 0
)
decode_t0(e::enc) = ( 
    ta((e>>(2*LEN_CHA + LEN_CHA + LEN_TA))&MSK_TA),   # w2: shift by 34
    ta((e>>(2*LEN_CHA + LEN_CHA))&MSK_TA),            # w1: shift by 24
    cha((e>>(2*LEN_CHA))&MSK_CHA),                    # A:  shift by 16
    ta((e)&MSK_TA)                                     # u:  shift by 0
)


###################################################################################
# 非終端記号の列を若い順に並び替えて，最も若い未使用番号を得る．
###################################################################################
function sort_find_least_new(V::Vector{cha})
    sort!(V)
    for i in eachindex(V)
        V[i] != cha(V[1] + i-1) && return cha(V[1] + i-1)
    end
    cha(V[1] + length(V))
end

###################################################################################
# すべての PYP layer の整合性チェック
###################################################################################

function check_consistency(pcfg::T) where T<:PCFG
    for name in fieldnames(typeof(c))
        model = getproperty(c, Meta.parse("$name") )
        if typeof(model) <: PYPModel
            check_consistency(model)
        end
    end
end

###################################################################################
# 確率の総和が1になるか，それぞれの y についてチェックする．
###################################################################################


