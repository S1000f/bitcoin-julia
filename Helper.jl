module Helper

export hash256, hash256toBigInt, big2hex, bytes2big, toByteArray, append

using SHA

function hash256(plain::String)
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

function bytes2big(bytes)::BigInt
  parse(BigInt, bytes2hex(bytes), base = 16)
end

function toByteArray(unit::Base.CodeUnits, multiple::Integer=1)::Vector{UInt8}
  arr = (UInt8)[]
  parsed = parse(UInt8, bytes2hex(unit))
  for i in 1:multiple
    push!(arr, parsed)
  end
  arr
end

function toByteArray(big::BigInt, len::Integer=32; bigEndian::Bool=true)::Vector{UInt8}
  hexstring = big2hex(big)
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
  arr[1:min(len, length(arr))]
end

function append(a::Vector{UInt8}...)
  arr = (UInt8)[]
  for item in a
    append!(arr, item)
  end
  arr
end

end # module