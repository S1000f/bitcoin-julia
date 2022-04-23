module Helper

export hash256, hash256toBigInt, int2hex, bytes2big, toByteArray, append, leftStrip, base58, base58Checksum, hash160, 
decodeVarints, encodeVarints, SIGHASH_ALL, SIGHASH_NONE, SIGHASH_SINGLE

using SHA
# https://github.com/JuliaCrypto/Ripemd.jl
# https://github.com/gdkrmr
using Ripemd

const SIGHASH_ALL = 1
const SIGHASH_NONE = 2
const SIGHASH_SINGLE = 3
const BASE58_ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

function hash256(plain)
  sha256(sha256(plain))
end

function hash256toBigInt(plain::String)::BigInt
  hash = hash256(plain)
  hex = bytes2hex(hash)
  parse(BigInt, hex, base = 16)
end

function int2hex(x::Integer; prefix::Bool=false)::String
  hex = string(x, base = 16)
  prefix ? "0x" * hex : hex
end

function bytes2big(bytes; bigEndian::Bool=true)::BigInt
  arr = bigEndian ? bytes : reverse(bytes)
  parse(BigInt, bytes2hex(arr), base = 16)
end

function append(args::Vector{UInt8}...)::Vector{UInt8}
  arr = (UInt8)[]
  for item in args
    append!(arr, item)
  end
  arr
end

function toByteArray(unit::Base.CodeUnits{UInt8, String}; mul::Integer=1)::Vector{UInt8}
  if unit == b""
    return b""
  end
  arr = (UInt8)[]
  parsed = parse(UInt8, bytes2hex(unit))
  for i in 1:mul
    push!(arr, parsed)
  end
  return arr
end

function toByteArray(hexstring::String, pad::Integer=1; bigEndian::Bool=true)::Vector{UInt8}
  arr = (UInt8)[]
  if isempty(hexstring)
    return arr
  end
  index = length(hexstring)
  while index > 0
    nextIdx = max(index - 1, 1)
    parsed = parse(UInt8, hexstring[nextIdx:index], base = 16)
    if bigEndian
      pushfirst!(arr, parsed)
    else
      push!(arr, parsed)
    end
    index -= 2
  end
  arrlen = length(arr)
  if arrlen >= pad
    return arr
  else
    more = pad - arrlen
    for i in 1:more
      if bigEndian
        pushfirst!(arr, 0x00)
      else
        push!(arr, 0x00)
      end
    end
    return arr
  end
end

function toByteArray(x::Integer, pad::Integer=1; bigEndian::Bool=true)::Vector{UInt8}
  hexstring = int2hex(x)
  toByteArray(hexstring, pad, bigEndian = bigEndian)
end

function leftStrip(bytearray::Vector{UInt8}, x::Union{Base.CodeUnits, UInt8})::Vector{UInt8}
  if x == b""
    return bytearray
  end
  arr = (UInt8)[]
  target = isa(x, UInt8) ? x : parse(UInt8, bytes2hex(x))
  isStrip = true
  for item in bytearray
    if item == target && isStrip
      continue
    else
      push!(arr, item)
      isStrip = false
    end
  end
  return arr
end

function base58(s::BigInt)::String
  count = 0
  num = toByteArray(s)
  for item in num
    if item == 0x00
      count += 1
    else
      break
    end
  end
  prefix = "1"^count
  result = ""
  while s > 0
    s, modrem = divrem(s, 58)
    result = BASE58_ALPHABET[modrem + 1] * result
  end
  prefix * result
end

function base58(s::Vector{UInt8})::String
  count = 0
  num = s
  for item in num
    if item == 0x00
      count += 1
    else
      break
    end
  end
  prefix = "1"^count
  result = ""
  num = bytes2big(s)
  while num > 0
    num, modrem = divrem(num, 58)
    result = BASE58_ALPHABET[modrem + 1] * result
  end
  prefix * result
end

function base58Checksum(b::Vector{UInt8})::String
  base58(append(b, hash256(b)[1:4]))
end

function hash160(s)
  ripemd160(sha256(s))
end

function decodeVarints(io::IO)::BigInt
  i = read(io, 1)[1]
  if i == 0xfd
    # 0xfd means the next two bytes are the number
    return bytes2big(read(io, 2), bigEndian=false)
  elseif i == 0xfe
    # 0xfe means the next four bytes are the number
    return bytes2big(read(io, 4), bigEndian=false)
  elseif i == 0xff
    # 0xff means the next eight bytes are the number
    return bytes2big(read(io, 8), bigEndian=false)
  else
    # anything else is just the integer
    return BigInt(i)
  end
end

function encodeVarints(i::Integer)
  if i < 0xfd
    return toByteArray(i)
  elseif i < 0x10000
    return append(toByteArray(0xfd), toByteArray(i, 2, bigEndian=false))
  elseif i < 0x100000000
    return append(toByteArray(0xfe), toByteArray(i, 4, bigEndian=false))
  elseif i < 0x10000000000000000
    return append(toByteArray(0xff), toByteArray(i, 8, bigEndian=false))
  else
    ArgumentError("integer too large")
  end
end

end # module