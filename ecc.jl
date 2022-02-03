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

IntegerOrNothing = Union{Integer, Nothing}

struct Point{T <: IntegerOrNothing}
  x::T
  y::T
  a::Integer
  b::Integer

  function Point{T}(x, y, a, b) where {T <: IntegerOrNothing}
    if (!isnothing(x) && !isnothing(y))
      @assert(y^2 == x^3 + a * x + b, "($x, $y) is not on the curve(secp256k1)")
    end
    new(x, y, a, b)
  end
  Point(x::T, y::T, a::Integer, b::Integer) where {T <: IntegerOrNothing} = Point{T}(x, y, a, b)
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

  if isnothing(p1.x)
    return p2
  elseif isnothing(p2.x)
    return p1
  end

  if (p1.x == p2.x && p1.y != p2.y)
    return Point(nothing, nothing, p1.a, p1.b)
  end
end

end # module