module Ecc

export AbstractField, AbstractPoint, FieldElement, Point, N, S256Field, S256Point, G, 
  Signature, PrivateKey, verify, signByECDSA, deterministicK, serializeBySEC, parseSEC, serializeByDER, parseDER, 
  hash160Point, address, wif

include("Helper.jl");  using .Helper
using Random
using SHA

import Base.isless
import Base.isequal
import Base.+
import Base.-
import Base.*
import Base.^
import Base./
import Base.inv
import Base.==
import Base.sqrt
import Base.convert

const P = big(2)^256 - big(2)^32 - big(977)
const A = 0
const B = 7
const N = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
const Gx = 0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798
const Gy = 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8

abstract type AbstractField
end

abstract type AbstractPoint
end

const Elements = Union{AbstractField, BigInt, Real, Nothing}

struct FieldElement{T, U <: Integer} <: AbstractField
  num::T
  prime::U

  function FieldElement{T, U}(num, prime) where {T, U <: Integer}
    @assert(0 <= num <= (prime - 1), "Num $num not in a field range from 0 to $(prime - 1)")
    new(num, prime)
  end
  FieldElement(num::T, prime::U) where {T, U <: Integer} = FieldElement{T, U}(num, prime)
end

function Base.show(io::IO, fe::AbstractField)
  print(io, "fieldElement : $(fe.prime)($(fe.num))")
end

function isequal(f1::AbstractField, f2::AbstractField)
  f1.num == f2.num && f1.prime == f2.prime
end

function ==(f1::AbstractField, f2::AbstractField)
  f1.num == f2.num && f1.prime == f2.prime
end

function isless(f1::AbstractField, f2::AbstractField)
  (f1.num, f1.prime) < (f2.num, f2.prime)
end

function +(f1::AbstractField, f2::AbstractField)::AbstractField
  @assert(f1.prime == f2.prime, "Cannot add numbers in diffrent Fields")
  num = mod(f1.num + f2.num, f1.prime)
  FieldElement(num, f1.prime)
end

function -(f1::AbstractField, f2::AbstractField)::AbstractField
  @assert(f1.prime == f2.prime, "Cannot subtract numbers in diffrent Fields")
  num = mod(f1.num - f2.num, f1.prime)
  FieldElement(num, f1.prime)
end

function *(f1::AbstractField, f2::AbstractField)::AbstractField
  @assert(f1.prime == f2.prime, "Cannot multiply numbers in diffrent Fields")
  num = mod(f1.num * f2.num, f1.prime)
  FieldElement(num, f1.prime)
end

# binary expansion calculating
function *(scala, f::AbstractField)::AbstractField
  coef = scala
  current = f
  result = FieldElement(0, f.prime)
  while coef > 0
    if coef & 1 > 0
      result += current
    end
    current += current
    coef >>= 1
  end
  result
end

function ^(f::AbstractField, exp)::AbstractField
  n = mod(exp, f.prime - 1)
  num = powermod(f.num, n, f.prime)
  FieldElement(num, f.prime)
end

function /(f1::AbstractField, f2::AbstractField)::AbstractField
  @assert(f1.prime == f2.prime, "Cannot divide numbers in diffrent Fields")
  num = mod(f1.num * powermod(f2.num, f1.prime - 2, f1.prime), f1.prime)
  FieldElement(num, f1.prime)
end

struct Point{T, U <: Elements} <: AbstractPoint
  x::T
  y::T
  a::U
  b::U

  function Point{T, U}(x, y, a, b)::AbstractPoint where {T, U <: Elements}
    if (!isnothing(x) && !isnothing(y))
      @assert(isequal(y^2, x^3 + (a * x) + b), "($x, $y) is not on the curve(secp256k1)")
    end
    new(x, y, a, b)
  end
  Point(x::T, y::T, a::U, b::U) where {T, U <: Elements} = Point{T, U}(x, y, a, b)
end

function Base.show(io::IO, p::AbstractPoint)
  toString = ""
  if isnothing(p.x) || isnothing(p.y)
    toString = "Point(infinity)"
  else
    toString = "Point($(p.x), $(p.y))_$(p.a)_$(p.b)"
  end
  print(io, toString)
end

function isequal(p1::AbstractPoint, p2::AbstractPoint)
  isequal(p1.x, p2.x) && isequal(p1.y, p2.y) && isequal(p1.a, p2.a) && isequal(p1.b, p2.b)
end

function ==(p1::AbstractPoint, p2::AbstractPoint)
  isequal(p1.x, p2.x) && isequal(p1.y, p2.y) && isequal(p1.a, p2.a) && isequal(p1.b, p2.b)
end

function +(p1::AbstractPoint, p2::AbstractPoint)::AbstractPoint
  @assert(p1.a == p2.a && p1.b == p2.b, "Points $p1, $p2 are not on the same curve")
  p1x, p1y, p2x, p2y = p1.x, p1.y, p2.x, p2.y

  if isequal(p1, p2) && isequal(p1y, 0 * p1x)
    return Point(nothing, nothing, p1.a, p1.b)
  end

  if isnothing(p1x)
    return p2
  elseif isnothing(p2x)
    return p1
  end

  # adding invertibility
  if isequal(p1x, p2x) && !isequal(p1y, p2y)
    return Point(nothing, nothing, p1.a, p1.b)
  elseif isequal(p1x, p2x) && isequal(p1y, p2y)
    s = (3 * p1x^2 + p1.a) / (2 * p1y)
    p3x = s^2 - 2 * p1x
    p3y = s * (p1x - p3x) - p1y
    return Point(p3x, p3y, p1.a, p1.b)
  elseif !isequal(p1x, p2x)
    s = (p2y - p1y) / (p2x - p1x)
    p3x = s^2 - p1x - p2x
    p3y = s * (p1x - p3x) - p1y
    return Point(p3x, p3y, p1.a, p1.b)
  end
end

# binary expansion calculating
function *(scala, p::AbstractPoint)::AbstractPoint
  coef = scala
  current = p
  result = Point(nothing, nothing, p.a, p.b)
  while coef > 0
    if coef & 1 > 0
      result += current
    end
    current += current
    coef >>= 1
  end
  result
end

struct S256Field <: AbstractField
  num::Integer
  prime::BigInt

  function S256Field(num::Integer)
    prime = P
    @assert(0 <= num <= (prime - 1), "Num $num not in a field range from 0 to $(prime - 1)")
    new(num, prime)
  end
end

function Base.show(io::IO, fe::S256Field)
  print(io, string(fe.num, base = 10, pad = 64))
end

function convert(::Type{S256Field}, x::FieldElement)
  S256Field(x.num)
end

function Base.sqrt(f::S256Field)::S256Field
  convert(S256Field, f^convert(BigInt, ((P + 1) / 4)))
end

const A_S256Field = S256Field(A)
const B_S256Field = S256Field(B)

struct S256Point <: AbstractPoint
  x::Union{S256Field, Nothing}
  y::Union{S256Field, Nothing}
  a::S256Field
  b::S256Field

  function S256Point(x, y)::AbstractPoint
    gx, gy, a, b = x, y, A_S256Field, B_S256Field

    if isnothing(x) || isnothing(y)
      return new(nothing, nothing, a, b)
    end

    gx = isa(x, AbstractField) ? convert(S256Field, x) : S256Field(x)
    gy = isa(y, AbstractField) ? convert(S256Field, y) : S256Field(y)
    @assert(isequal(gy^2, gx^3 + (a * gx) + b), "($x, $y) is not on the curve(secp256k1)")
    return new(gx, gy, a, b)
  end
end

function convert(::Type{S256Point}, p::Point)
  S256Point(p.x, p.y)
end

const G = S256Point(Gx, Gy)

struct Signature
  r::BigInt
  s::BigInt
end

function Base.show(io::IO, sig::Signature)
  print(io, "Signature($(sig.r), $(sig.s))")
end

function verify(p::S256Point, z::BigInt, sig::Signature)::Bool
  sInv = powermod(sig.s, N - 2, N)
  u = z * mod(sInv, N)
  v = sig.r * mod(sInv, N)
  total = u * G + v * p
  return total.x.num == sig.r
end

struct PrivateKey
  secret::BigInt
  point::S256Point

  function PrivateKey(secret)
    new(secret, convert(S256Point, secret * G))
  end
end

function signByECDSA(pk::PrivateKey, z::BigInt)::Signature
  # k = rand(0:N)
  k = deterministicK(pk, z)
  r = (k * G).x.num
  kInv = powermod(k, N - 2, N)
  s = mod(((z + r * pk.secret) * kInv), N)
  if s > N / 2
    s = N - s
  end
  Signature(r, s)
end

# RFC6979
function deterministicK(pk::PrivateKey, z::BigInt)::BigInt
  k = toByteArray(b"\x00", mul = 32)
  v = toByteArray(b"\x01", mul = 32)

  if z > N
    z -= N
  end

  zBytes = toByteArray(z, 32)
  secretBytes = toByteArray(pk.secret, 32)
  k = hmac_sha256(k, append(v, toByteArray(b"\x00"), secretBytes, zBytes))
  v = hmac_sha256(k, v)
  k = hmac_sha256(k, append(v, toByteArray(b"\x01"), secretBytes, zBytes))
  v = hmac_sha256(k, v)

  while true
    v = hmac_sha256(k, v)
    candidate = bytes2big(v)
    if candidate >= 1 && candidate < N
      return candidate
    end
    k = hmac_sha256(k, append(v, toByteArray(b"\x00")))
    v = hmac_sha256(k, v)
  end
end

"""
returns the binary version of the SEC format
"""
function serializeBySEC(p::AbstractPoint; compressed::Bool=true)::Vector{UInt8}
  xb = toByteArray(p.x.num, 32)
  if compressed
    return mod(p.y.num, 2) == 0 ? append(toByteArray(b"\x02"), xb) : append(toByteArray(b"\x03"), xb)
  else
    return append(toByteArray(b"\x04"), xb, toByteArray(p.y.num, 32))
  end
end

"""
returns a Point object from a SEC binary (not hexstring)
"""
function parseSEC(sec::Vector{UInt8})::S256Point
  if sec[1] == 4
    return S256Point(bytes2big(sec[2:33]), bytes2big(sec[34:65]))
  end
  
  isEven = sec[1] == 2
  x = S256Field(bytes2big(sec[2:end]))
  # right side of the equation y^2 = x^3 + 7
  alpha = x^3 + S256Field(B)
  # solve for left side
  beta = sqrt(convert(S256Field, alpha))

  if isEven
    return S256Point(x, mod(beta.num, 2) == 0 ? beta : S256Field(P - beta.num))
  else
    return S256Point(x, mod(beta.num, 2) == 0 ? S256Field(P - beta.num) : beta)
  end
end

function serializeByDER(sig::Signature)::Vector{UInt8}
  rbin = toByteArray(sig.r, 32)
  # remove all null bytes at the beginning
  rbin = leftStrip(rbin, b"\x00")
  # if rbin has a high bit, add a \x00
  if rbin[1] & 0x80 > 0
    rbin = append(toByteArray(b"\x00"), rbin)
  end
  result = append(toByteArray(2), toByteArray(length(rbin)), rbin)

  sbin = toByteArray(sig.s, 32)
  # remove all null bytes at the beginning
  sbin = leftStrip(sbin, b"\x00")
  # if sbin has a high bit, add a \x00
  if sbin[1] & 0x80 > 0
    sbin = append(toByteArray(b"\x00"), sbin)
  end
  result = append(result, toByteArray(2), toByteArray(length(sbin)), sbin)

  append(toByteArray(0x30), toByteArray(length(result)), result)
end

function parseDER(x::Vector{UInt8})::Signature
  s = IOBuffer(x)
  compound = read(s, 1)[1]
  if compound != 0x30
    ArgumentError("Bad Signature")
  end
  len = read(s, 1)[1]
  if len + 2 != length(x)
    ArgumentError("Bad Signature Length")
  end
  marker = read(s, 1)[1]
  if marker != 0x02
    ArgumentError("Bad Signature")
  end
  rlen = read(s, 1)[1]
  r = bytes2big(read(s, rlen))
  marker = read(s, 1)[1]
  if marker != 0x02
    ArgumentError("Bad signature")
  end
  slen = read(s, 1)[1]
  s = bytes2big(read(s, slen))
  if length(x) != 6 + rlen + slen
    ArgumentError("Signature too long")
  end
  Signature(r, s)
end

function hash160Point(p::S256Point; compressed::Bool=true)
  hash160(serializeBySEC(p, compressed = compressed))
end

function address(p::S256Point; compressed::Bool=true, testnet::Bool=false)::String
  h160 = hash160Point(p, compressed = compressed)
  prefix = testnet ? 0x6f : b"\x00"
  base58Checksum(append(toByteArray(prefix), h160))
end

function wif(pk::PrivateKey; compressed::Bool=true, testnet::Bool=false)::String
  secretByte = toByteArray(pk.secret, 32)
  prefix = testnet ? 0xef : 0x80
  if compressed
    return base58Checksum(append(toByteArray(prefix), secretByte, toByteArray(b"\x01")))
  else
    return base58Checksum(append(toByteArray(prefix), secretByte))
  end
end

end # module