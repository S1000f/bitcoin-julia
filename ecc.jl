
import Base.isless
import Base.isequal
import Base.+
import Base.-
import Base.*
import Base.^
import Base./
import Base.inv

struct FieldElement
  num::Int64
  prime::Int64

  function FieldElement(num::Int64, prime::Int64)
    @assert(0 <= num <= (prime - 1), "Num $num not in a field range from 0 to $(prime - 1)")
    new(num, prime)
  end
end

function Base.show(io::IO, fe::FieldElement)
  print(io, "fieldElement : $(fe.prime)($(fe.num))")
end

function isequal(fe1::FieldElement, fe2::FieldElement)
  return (fe1.num, fe1.prime) == (fe2.num, fe2.prime)
end

function isless(fe1::FieldElement, fe2::FieldElement)
  return (fe1.num, fe1.prime) < (fe2.num, fe2.prime)
end

function +(fe1::FieldElement, fe2::FieldElement)
  @assert(fe1.prime == fe2.prime, "Cannot add numbers in diffrent Fields")
  num = mod(fe1.num + fe2.num, fe1.prime)
  return FieldElement(num, fe1.prime)
end

function -(fe1::FieldElement, fe2::FieldElement)
  @assert(fe1.prime == fe2.prime, "Cannot subtract numbers in diffrent Fields")
  num = mod(fe1.num - fe2.num, fe1.prime)
  return FieldElement(num, fe1.prime)
end

function *(fe1::FieldElement, fe2::FieldElement)
  @assert(fe1.prime == fe2.prime, "Cannot multiply numbers in diffrent Fields")
  num = mod(fe1.num * fe2.num, fe1.prime)
  return FieldElement(num, fe1.prime)
end

function ^(fe::FieldElement, exp::Integer)
  n = mod(exp, fe.prime - 1)
  num = powermod(fe.num, n, fe.prime)
  return FieldElement(num, fe.prime)
end

function /(fe1::FieldElement, fe2::FieldElement)
  @assert(fe1.prime == fe2.prime, "Cannot divide numbers in diffrent Fields")
  num = mod(fe1.num * powermod(fe2.num, fe1.prime - 2, fe1.prime), fe1.prime)
  return FieldElement(num, fe1.prime)
end
