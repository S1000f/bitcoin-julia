using Test
include("ecc.jl");  using .Ecc

@testset "FieldElement: finite field and modulo" begin
  a = FieldElement(7, 13)
  b = FieldElement(12, 13)
  c = FieldElement(6, 13)
  @test a + b == c

  d = FieldElement(3, 13)
  e = FieldElement(12, 13)
  f = FieldElement(10, 13)
  @test d * e == f

  pow1 = FieldElement(3, 13)
  pow2 = FieldElement(1, 13)
  @test pow1^3 == pow2

  pow3 = FieldElement(7, 13)
  pow4 = FieldElement(8, 13)
  @test pow3^.-3 == pow4
end

@testset "Point: is a point on the secp256k1 curve" begin
  @test_nowarn p1 = Point(-1, -1, 5, 7)
  @test_throws AssertionError p2 = Point(-1, -2, 5, 7)

  # adding Point
  p3 = Point(-1, -1, 5, 7)
  p4 = Point(-1, 1, 5, 7)
  inf = Point(nothing, nothing, 5, 7)
  @test p3 + inf == p3
  @test inf + p4 == p4
  @test p3 + p4 == inf

end