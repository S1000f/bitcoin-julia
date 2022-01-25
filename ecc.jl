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

struct Point
  x::Integer
  y::Integer
  a::Integer
  b::Integer

  function Point(x::Integer, y::Integer, a::Integer, b::Integer)
    @assert(y^2 == x^3 + a * x + b, "($x, $y) is not on the curve(secp256k1)")
    new(x, y, a, b)
  end
end

function isequal(p1::Point, p2::Point)
  p1.x == p2.x && p1.y == p2.y && p1.a == p2.a && p1.b == p2.b
end

end # module