module Op

export OP_CODE_FUNCTIONS, OP_CODE_NAMES, encodeNum, decodeNum

include("Ecc.jl");  using .Ecc
include("Helper.jl");  using .Helper

using Logging
using SHA

function encodeNum(num::Integer)::Vector{UInt8}
  if num == 0
    return b""
  end

  absNum = abs(num)
  negative = num < 0
  result = (UInt8)[]

  while absNum > 0
    append!(result, (absNum & 0xff))
    absNum >>= 8
  end

  if result[end] & 0x80 > 0
    if negative
      append!(result, 0x80)
    else
      append!(result, 0)
    end
  elseif negative
    result[end] |= 0x80
  end

  result
end

function decodeNum(element::Vector{UInt8})::Integer
  if element == b""
    return 0
  end

  bigEndian = reverse(element)
  negative = false
  result = 0

  if bigEndian[1] & 0x80 > 0
    negative = true
    result = bigEndian[1] & 0x7f
  else
    negative = false
    result = bytes2big(bigEndian[1])
  end

  for c in bigEndian[2:end]
    result <<= 8
    result += c
  end

  if negative
    return -result
  else
    return result
  end
end

OP_CODE_FUNCTIONS = Dict(
  0 => () -> "OP_0",
  76 => () -> "OP_PUSHDATA1",
  77 => () -> "OP_PUSHDATA2",
  78 => () -> "OP_PUSHDATA4",
  79 => () -> "OP_1NEGATE",
  81 => () -> "OP_1",
  # OP_2
  82 => stack::Vector{Any} -> begin
    push!(stack, encodeNum(2))
    true
  end,
  83 => () -> "OP_3",
  84 => () -> "OP_4",
  85 => () -> "OP_5",
  # OP_6
  86 => stack::Vector{Any} -> begin
    push!(stack, encodeNum(6))
    true
  end,
  87 => () -> "OP_7",
  88 => () -> "OP_8",
  89 => () -> "OP_9",
  90 => () -> "OP_10",
  91 => () -> "OP_11",
  92 => () -> "OP_12",
  93 => () -> "OP_13",
  94 => () -> "OP_14",
  95 => () -> "OP_15",
  96 => () -> "OP_16",
  97 => () -> "OP_NOP",
  99 => () -> "OP_IF",
  100 => () -> "OP_NOTIF",
  103 => () -> "OP_ELSE",
  104 => () -> "OP_ENDIF",
  # OP_VERIFY
  105 => stack::Vector{Any} -> begin
    if length(stack) < 1
      return false
    end
    element = pop!(stack)
    return decodeNum(element) != 0
  end,
  106 => () -> "OP_RETURN",
  107 => () -> "OP_TOALTSTACK",
  108 => () -> "OP_FROMALTSTACK",
  109 => () -> "OP_2DROP",
  # OP_2DUP
  110 => stack::Vector{Any} -> begin
    if length(stack) < 2
      return false
    end
    append!(stack, stack[end-1:end])
    return true
  end,
  111 => () -> "OP_3DUP",
  112 => () -> "OP_2OVER",
  113 => () -> "OP_2ROT",
  114 => () -> "OP_2SWAP",
  115 => () -> "OP_IFDUP",
  116 => () -> "OP_DEPTH",
  117 => () -> "OP_DROP",
  # OP_DUP
  118 => stack::Vector{Any} -> begin
    if length(stack) < 1
      return false
    end
    push!(stack, stack[end])
    return true
  end,

  119 => () -> "OP_NIP",
  120 => () -> "OP_OVER",
  121 => () -> "OP_PICK",
  122 => () -> "OP_ROLL",
  123 => () -> "OP_ROT",
  # OP_SWAP
  124 => stack::Vector{Any} -> begin
    if length(stack) < 2
      return false
    end
    element = popat!(stack, length(stack) - 1)
    push!(stack, element)
    return true
  end,
  125 => () -> "OP_TUCK",
  130 => () -> "OP_SIZE",
  # OP_EQUAL
  135 => stack::Vector{Any} -> begin
    if length(stack) < 2
      return false
    end
    element1 = pop!(stack)
    element2 = pop!(stack)
    if element1 == element2
      push!(stack, encodeNum(1))
    else
      push!(stack, encodeNum(0))
    end
    return true
  end,
  # OP_EQUALVERIFY
  136 => stack::Vector{Any} -> begin
    return OP_CODE_FUNCTIONS[135](stack) && OP_CODE_FUNCTIONS[105](stack)
  end,
  139 => () -> "OP_1ADD",
  140 => () -> "OP_1SUB",
  143 => () -> "OP_NEGATE",
  144 => () -> "OP_ABS",
  # OP_NOT
  145 => stack::Vector{Any} -> begin
    if length(stack) < 1
      return false
    end
    element = pop!(stack)
    if decodeNum(element) == 0
      push!(stack, encodeNum(1))
    else
      push!(stack, encodeNum(0))
    end
    return true
  end,
  146 => () -> "OP_0NOTEQUAL",
  # OP_ADD
  147 => stack::Vector{Any} -> begin
    if length(stack) < 2
      return false
    end
    num1 = decodeNum(pop!(stack))
    num2 = decodeNum(pop!(stack))
    push!(stack, encodeNum(num1 + num2))
    return true
  end,
  148 => () -> "OP_SUB",
  # OP_MUL
  149 => stack::Vector{Any} -> begin
    if length(stack) < 2
      return false
    end    
    num1 = decodeNum(pop!(stack))
    num2 = decodeNum(pop!(stack))
    push!(stack, encodeNum(num1 * num2))
    return true
  end,
  154 => () -> "OP_BOOLAND",
  155 => () -> "OP_BOOLOR",
  156 => () -> "OP_NUMEQUAL",
  157 => () -> "OP_NUMEQUALVERIFY",
  158 => () -> "OP_NUMNOTEQUAL",
  159 => () -> "OP_LESSTHAN",
  160 => () -> "OP_GREATERTHAN",
  161 => () -> "OP_LESSTHANOREQUAL",
  162 => () -> "OP_GREATERTHANOREQUAL",
  163 => () -> "OP_MIN",
  164 => () -> "OP_MAX",
  165 => () -> "OP_WITHIN",
  166 => () -> "OP_RIPEMD160",
  # OP_SHA1
  167 => stack::Vector{Any} -> begin
    if length(stack) < 1
      return false
    end
    element = pop!(stack)
    push!(stack, sha1(element))
    return true
  end,
  168 => () -> "OP_SHA256",
  # OP_HASH160
  169 => stack::Vector{Any} -> begin
    if length(stack) < 1
      return false
    end
    element = pop!(stack)
    push!(stack, hash160(element))
    return true
  end,
  # OP_HASH256
  170 => stack::Vector{Any} -> begin
    if length(stack) < 1
      return false
    end
    element = pop!(stack)
    push!(stack, hash256(element))
    return true
  end,

  171 => () -> "OP_CODESEPARATOR",
  # OP_CHECKSIG
  172 => (stack::Vector{Any}, z::Integer) -> begin
    if length(stack) < 2
      return false
    end
    secPubkey = pop!(stack)
    derSig = pop!(stack)[1:end - 1]
    point = ""
    sig = ""
    try
      point = parseSEC(secPubkey)
      sig = parseDER(derSig)
    catch e
      @info e
      return false
    end
    if verify(point, z, sig)
      push!(stack, encodeNum(1))
    else
      push!(stack, encodeNum(0))
    end
    return true
  end,

  173 => () -> "OP_CHECKSIGVERIFY",
  174 => () -> "OP_CHECKMULTISIG",
  175 => () -> "OP_CHECKMULTISIGVERIFY",
  176 => () -> "OP_NOP1",
  177 => () -> "OP_CHECKLOCKTIMEVERIFY",
  178 => () -> "OP_CHECKSEQUENCEVERIFY",
  179 => () -> "OP_NOP4",
  180 => () -> "OP_NOP5",
  181 => () -> "OP_NOP6",
  182 => () -> "OP_NOP7",
  183 => () -> "OP_NOP8",
  184 => () -> "OP_NOP9",
  185 => () -> "OP_NOP10",
)

OP_CODE_NAMES = Dict(
  0 => "OP_0",
  76 => "OP_PUSHDATA1",
  77 => "OP_PUSHDATA2",
  78 => "OP_PUSHDATA4",
  79 => "OP_1NEGATE",
  81 => "OP_1",
  82 => "OP_2",
  83 => "OP_3",
  84 => "OP_4",
  85 => "OP_5",
  86 => "OP_6",
  87 => "OP_7",
  88 => "OP_8",
  89 => "OP_9",
  90 => "OP_10",
  91 => "OP_11",
  92 => "OP_12",
  93 => "OP_13",
  94 => "OP_14",
  95 => "OP_15",
  96 => "OP_16",
  97 => "OP_NOP",
  99 => "OP_IF",
  100 => "OP_NOTIF",
  103 => "OP_ELSE",
  104 => "OP_ENDIF",
  105 => "OP_VERIFY",
  106 => "OP_RETURN",
  107 => "OP_TOALTSTACK",
  108 => "OP_FROMALTSTACK",
  109 => "OP_2DROP",
  110 => "OP_2DUP",
  111 => "OP_3DUP",
  112 => "OP_2OVER",
  113 => "OP_2ROT",
  114 => "OP_2SWAP",
  115 => "OP_IFDUP",
  116 => "OP_DEPTH",
  117 => "OP_DROP",
  118 => "OP_DUP",
  119 => "OP_NIP",
  120 => "OP_OVER",
  121 => "OP_PICK",
  122 => "OP_ROLL",
  123 => "OP_ROT",
  124 => "OP_SWAP",
  125 => "OP_TUCK",
  130 => "OP_SIZE",
  135 => "OP_EQUAL",
  136 => "OP_EQUALVERIFY",
  139 => "OP_1ADD",
  140 => "OP_1SUB",
  143 => "OP_NEGATE",
  144 => "OP_ABS",
  145 => "OP_NOT",
  146 => "OP_0NOTEQUAL",
  147 => "OP_ADD",
  148 => "OP_SUB",
  149 => "OP_MUL",
  154 => "OP_BOOLAND",
  155 => "OP_BOOLOR",
  156 => "OP_NUMEQUAL",
  157 => "OP_NUMEQUALVERIFY",
  158 => "OP_NUMNOTEQUAL",
  159 => "OP_LESSTHAN",
  160 => "OP_GREATERTHAN",
  161 => "OP_LESSTHANOREQUAL",
  162 => "OP_GREATERTHANOREQUAL",
  163 => "OP_MIN",
  164 => "OP_MAX",
  165 => "OP_WITHIN",
  166 => "OP_RIPEMD160",
  167 => "OP_SHA1",
  168 => "OP_SHA256",
  169 => "OP_HASH160",
  170 => "OP_HASH256",
  171 => "OP_CODESEPARATOR",
  172 => "OP_CHECKSIG",
  173 => "OP_CHECKSIGVERIFY",
  174 => "OP_CHECKMULTISIG",
  175 => "OP_CHECKMULTISIGVERIFY",
  176 => "OP_NOP1",
  177 => "OP_CHECKLOCKTIMEVERIFY",
  178 => "OP_CHECKSEQUENCEVERIFY",
  179 => "OP_NOP4",
  180 => "OP_NOP5",
  181 => "OP_NOP6",
  182 => "OP_NOP7",
  183 => "OP_NOP8",
  184 => "OP_NOP9",
  185 => "OP_NOP10",
)

# module
end