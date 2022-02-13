module Helper

export hash256, hash256toBigInt, big2hex, bytes2big, toByteArray, append, leftStrip, base58, base58Checksum, hash160

using SHA
# https://github.com/JuliaCrypto/Ripemd.jl
# https://github.com/gdkrmr
using Ripemd

function hash256(plain)
  sha256(sha256(plain))
end

function hash256toBigInt(plain::String)::BigInt
  hash = hash256(plain)
  hex = bytes2hex(hash)
  parse(BigInt, hex, base = 16)
end

function big2hex(big::BigInt)::String
  string(big, base = 16)
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
  arr = (UInt8)[]
  parsed = parse(UInt8, bytes2hex(unit))
  for i in 1:mul
    push!(arr, parsed)
  end
  arr
end

function toByteArray(hexstring::String, pad::Integer=1; bigEndian::Bool=true)::Vector{UInt8}
  arr = (UInt8)[]
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

function toByteArray(x::Union{BigInt, Integer}, pad::Integer=1; bigEndian::Bool=true)::Vector{UInt8}
  hexstring = isa(x, BigInt) ? big2hex(x) : string(x, base = 16)
  toByteArray(hexstring, pad, bigEndian = bigEndian)
end

function leftStrip(bytearray::Vector{UInt8}, x::Union{Base.CodeUnits, UInt8})::Vector{UInt8}
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
  arr
end

const BASE58_ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

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

end # module