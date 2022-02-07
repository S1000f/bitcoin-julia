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

end # module