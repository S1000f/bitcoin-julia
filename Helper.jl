module Helper

export hash256, hash256toBigInt, big2hex

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


# RFC6979
function deterministicK(pk, z::BigInt)::BigInt
  b00 = parse(UInt8, bytes2hex(b"\x00"))
  b01 = parse(UInt8, bytes2hex(b"\x01"))
  k = Array([b00])
  v = Array([b01])
  for i in 1:31
    push!(k, b00)
    push!(v, b01)
  end

  if z > N
    z -= N
  end

  zBytes = codeunits(big2hex(z))
  secretBytes = codeunits(big2hex(pk.secret))

  vCopy = copy(v)
  push!(vCopy, b00)
  append!(vCopy, secretBytes)
  append!(vCopy, zBytes)
  k = hmac_sha256(k, vCopy)
  v = hmac_sha256(k, v)

  vCopy2 = copy(v)
  push!(vCopy2, b01)
  append!(vCopy2, secretBytes)
  append!(vCopy2, zBytes)
  k = hmac_sha256(k, vCopy2)
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

bit = parse(UInt8, bytes2hex(b"\x00"))
byteArr = [bit]
arr = (UInt8)[]

b00 = b"\x00"
println(typeof(b00))
println(b00)

z = 0xbc62d4b80d9e36da29c16c5d4d9f11731f36052c72401a76c23c0fb5a9b74423

str = "ff"
strParsed = parse(UInt8, str, base = 16)

function toByteArray(unit::Base.CodeUnits, len::Integer=32; bigendian::Bool=true)::Vector{UInt8}
  [parse(UInt8, bytes2hex(unit))]
end

function toByteArray(big::BigInt, len::Integer=32; bigEndian::Bool=true)
  hexstring = big2hex(big)
  arr = (UInt8)[]
  index = 1
  while index < sizeof(hexstring)
    chunk = hexstring[index:index+1]
    parsed = parse(UInt8, chunk, base = 16)
    if bigEndian
      push!(arr, parsed)
    else
      pushfirst!(arr, parsed)
    end
    index += 2
  end
  arr[1:len]
end

rs = toByteArray(z)
println(rs)
println(typeof(rs))
println(length(rs))


end # module