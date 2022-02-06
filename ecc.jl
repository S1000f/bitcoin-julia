module Ecc

export FieldElement, Point, N, S256Field, S256Point, G

import Base.isless
import Base.isequal
import Base.+
import Base.-
import Base.*
import Base.^
import Base./
import Base.inv
import Base.==

const P = big(2)^256 - big(2)^32 - big(977)
const A = 0
const B = 7
const N = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
const Gx = 0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798
const Gy = 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8

abstract type AbstractField
end

abstract type AbstactPoint
end

const BigOrSmall = Union{BigInt, Integer}
const Elements = Union{AbstractField, BigInt, Real, Nothing}

struct FieldElement{T, U <: BigOrSmall} <: AbstractField
  num::T
  prime::U

  function FieldElement{T, U}(num, prime) where {T, U <: BigOrSmall}
    @assert(0 <= num <= (prime - 1), "Num $num not in a field range from 0 to $(prime - 1)")
    new(num, prime)
  end
  FieldElement(num::T, prime::U) where {T, U <: BigOrSmall} = FieldElement{T, U}(num, prime)
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
    if (coef & 1) == true
      result += current
    end
    current += current
    coef >>= 1
  end
  result
end

function ^(f::AbstractField, exp::Integer)::AbstractField
  n = mod(exp, f.prime - 1)
  num = powermod(f.num, n, f.prime)
  FieldElement(num, f.prime)
end

function /(f1::AbstractField, f2::AbstractField)::AbstractField
  @assert(f1.prime == f2.prime, "Cannot divide numbers in diffrent Fields")
  num = mod(f1.num * powermod(f2.num, f1.prime - 2, f1.prime), f1.prime)
  FieldElement(num, f1.prime)
end

struct Point{T, U <: Elements} <: AbstactPoint
  x::T
  y::T
  a::U
  b::U

  function Point{T, U}(x, y, a, b)::AbstactPoint where {T, U <: Elements}
    if (!isnothing(x) && !isnothing(y))
      @assert(isequal(y^2, x^3 + (a * x) + b), "($x, $y) is not on the curve(secp256k1)")
    end
    new(x, y, a, b)
  end
  Point(x::T, y::T, a::U, b::U) where {T, U <: Elements} = Point{T, U}(x, y, a, b)
end

function Base.show(io::IO, p::AbstactPoint)
  toString = ""
  if isnothing(p.x) || isnothing(p.y)
    toString = "Point(infinity)"
  else
    toString = "Point($(p.x), $(p.y))_$(p.a)_$(p.b)"
  end
  print(io, toString)
end

function isequal(p1::AbstactPoint, p2::AbstactPoint)
  isequal(p1.x, p2.x) && isequal(p1.y, p2.y) && isequal(p1.a, p2.a) && isequal(p1.b, p2.b)
end

function ==(p1::AbstactPoint, p2::AbstactPoint)
  isequal(p1.x, p2.x) && isequal(p1.y, p2.y) && isequal(p1.a, p2.a) && isequal(p1.b, p2.b)
end

function +(p1::AbstactPoint, p2::AbstactPoint)::AbstactPoint
  @assert(p1.a == p2.a && p1.b == p2.b, "Points $p1, $p2 are not on the same curve")

  p1x = p1.x
  p1y = p1.y
  p2x = p2.x
  p2y = p2.y

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

# function *(scala::Integer, p::Point)
#   product = Point(nothing, nothing, p.a, p.b)
#   for i in 1:scala
#     product += p
#   end
#   product
# end

# binary expansion calculating
function *(scala, p::AbstactPoint)::AbstactPoint
  coef = scala
  current = p
  result = Point(nothing, nothing, p.a, p.b)
  while coef > 0
    if (coef & 1) == true
      result += current
    end
    current += current
    coef >>= 1
  end
  result
end

struct S256Field <: AbstractField
  num::BigOrSmall
  prime::BigInt

  function S256Field(num::BigOrSmall)
    prime = P
    @assert(0 <= num <= (prime - 1), "Num $num not in a field range from 0 to $(prime - 1)")
    new(num, prime)
  end
end

function Base.show(io::IO, fe::S256Field)
  print(io, string(fe.num, base = 10, pad = 64))
end

const A_S256Field = S256Field(A)
const B_S256Field = S256Field(B)
struct S256Point <: AbstactPoint
  x
  y
  a::S256Field
  b::S256Field

  function S256Point(x, y)::AbstactPoint
    gx = x
    gy = y
    a = A_S256Field
    b = B_S256Field
    if (!isnothing(x) && !isnothing(y))
      gx = S256Field(x)
      gy = S256Field(y)
      @assert(isequal(gy^2, gx^3 + (a * gx) + b), "($x, $y) is not on the curve(secp256k1)")
    end
    new(gx, gy, a, b)
  end
end

# binary expansion calculating
function *(scala, p::S256Point)::AbstactPoint
  coef = mod(scala, N)
  current = p
  result = S256Point(nothing, nothing)
  while coef > 0
    if (coef & 1) == true
      result += current
    end
    current += current
    coef >>= 1
  end
  result
end

const G = S256Point(Gx, Gy)

end # module