module Helper

export hash256, hash256toBigInt, big2hex, toByteArray, append

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
  index = 1
  while index < sizeof(hexstring)
    parsed = parse(UInt8, hexstring[index:index + 1], base = 16)
    if bigEndian
      push!(arr, parsed)
    else
      pushfirst!(arr, parsed)
    end
    index += 2
  end
  arr[1:len]
end

function append(a::Vector{UInt8}, b::Vector{UInt8})::Vector{UInt8}
  arr = (UInt8)[]
  append!(arr, a)
  append!(arr, b)
  arr
end


# RFC6979
function deterministicK(pk, z::BigInt)::BigInt
  k = toByteArray(b"\x00", 32)
  v = toByteArray(b"\x01", 32)

  if z > N
    z -= N
  end

  zBytes = toByteArray(z)
  secretBytes = toByteArray(pk.secret)

  k = hmac_sha256(k, append(append(v, secretBytes), zBytes))
  v = hmac_sha256(k, v)
  k = hmac_sha256(k, append(append(v, secretBytes), zBytes))
  v = hmac_sha256(k, v)

  while true
    v = hmac_sha256(k, v)
    candidate = parse(BigInt, bytes2hex(v), base = 16) 
    if candidate >= 1 && candidate < N
      return candidate
    end
    vCopy3 = copy(v)
    push!(vCopy3, b00)
    k = hmac_sha256(k, vCopy3)
    v = hmac_sha256(k, v)
  end
end



end # module