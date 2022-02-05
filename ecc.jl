module Ecc

export FieldElement, Point

import Base.isless
import Base.isequal
import Base.+
import Base.-
import Base.*
import Base.^
import Base./
import Base.inv

struct FieldElement
  num::Integer
  prime::Integer

  function FieldElement(num::Integer, prime::Integer)
    @assert(0 <= num <= (prime - 1), "Num $num not in a field range from 0 to $(prime - 1)")
    new(num, prime)
  end
end

function Base.show(io::IO, fe::FieldElement)
  print(io, "fieldElement : $(fe.prime)($(fe.num))")
end

function isequal(fe1::FieldElement, fe2::FieldElement)
  (fe1.num, fe1.prime) == (fe2.num, fe2.prime)
end

function isless(fe1::FieldElement, fe2::FieldElement)
  (fe1.num, fe1.prime) < (fe2.num, fe2.prime)
end

function +(fe1::FieldElement, fe2::FieldElement)
  @assert(fe1.prime == fe2.prime, "Cannot add numbers in diffrent Fields")
  num = mod(fe1.num + fe2.num, fe1.prime)
  FieldElement(num, fe1.prime)
end

function -(fe1::FieldElement, fe2::FieldElement)
  @assert(fe1.prime == fe2.prime, "Cannot subtract numbers in diffrent Fields")
  num = mod(fe1.num - fe2.num, fe1.prime)
  FieldElement(num, fe1.prime)
end

function *(fe1::FieldElement, fe2::FieldElement)
  @assert(fe1.prime == fe2.prime, "Cannot multiply numbers in diffrent Fields")
  num = mod(fe1.num * fe2.num, fe1.prime)
  FieldElement(num, fe1.prime)
end

function *(scala::Integer, fe::FieldElement)
  product = FieldElement(0, fe.prime)
  for i in 1:scala
    product += fe
  end
  product
end

function ^(fe::FieldElement, exp::Integer)
  n = mod(exp, fe.prime - 1)
  num = powermod(fe.num, n, fe.prime)
  FieldElement(num, fe.prime)
end

function /(fe1::FieldElement, fe2::FieldElement)
  @assert(fe1.prime == fe2.prime, "Cannot divide numbers in diffrent Fields")
  num = mod(fe1.num * powermod(fe2.num, fe1.prime - 2, fe1.prime), fe1.prime)
  FieldElement(num, fe1.prime)
end

Element = Union{FieldElement, Real, Nothing}

struct Point{T, U <: Element}
  x::T
  y::T
  a::U
  b::U

  function Point{T, U}(x, y, a, b) where {T, U <: Element}
    if (!isnothing(x) && !isnothing(y))
      @assert(y^2 == x^3 + a * x + b, "($x, $y) is not on the curve(secp256k1)")
    end
    new(x, y, a, b)
  end
  Point(x::T, y::T, a::U, b::U) where {T, U <: Element} = Point{T, U}(x, y, a, b)
end

function Base.show(io::IO, p::Point)
  toString = ""
  if isnothing(p.x) || isnothing(p.y)
    toString = "Point(infinity)"
  else
    toString = "Point($(p.x), $(p.y))_$(p.a)_$(p.b)"
  end
  print(io, toString)
end

function isequal(p1::Point, p2::Point)
  p1.x == p2.x && p1.y == p2.y && p1.a == p2.a && p1.b == p2.b
end

function +(p1::Point, p2::Point)
  @assert(p1.a == p2.a && p1.b == p2.b, "Points $p1, $p2 are not on the same curve")

  p1x = p1.x
  p1y = p1.y
  p2x = p2.x
  p2y = p2.y

  if p1 == p2 && p1y == 0 * p1x
    return Point(nothing, nothing, p1.a, p1.b)
  end

  if isnothing(p1x)
    return p2
  elseif isnothing(p2x)
    return p1
  end

  # adding invertibility
  if p1x == p2x && p1y != p2y
    return Point(nothing, nothing, p1.a, p1.b)
  elseif p1x == p2x && p1y == p2y
    s = (3 * p1x^2 + p1.a) / (2 * p1y)
    p3x = s^2 - 2 * p1x
    p3y = s * (p1x - p3x) - p1y
    return Point(p3x, p3y, p1.a, p1.b)
  elseif p1x != p2x
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
function *(scala::Integer, p::Point)
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

end # module