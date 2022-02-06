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
  p24 = Point(2, 5, 5, 7)
  p25 = Point(-1, -1, 5, 7)
  @test p24 + p25 == Point(3.0, -7.0, 5, 7)
end

function testAddingPoints(order, a, b, cases)
  for (x1, y1, x2, y2, x3, y3) in cases
    p1 = Point(FieldElement(x1, order), FieldElement(y1, order), a, b)
    p2 = Point(FieldElement(x2, order), FieldElement(y2, order), a, b)
    ans = Point(FieldElement(x3, order), FieldElement(y3, order), a, b)
    @test p1 + p2 == ans
  end
end

@testset "test the curve on finite field" begin
  prime = 223
  a = FieldElement(0, prime)
  b = FieldElement(7, prime)

  validPoints = [(192, 105), (17, 56), (1, 193)]
  invalidPoints = [(200, 119), (42, 99)]

  for (x, y) in validPoints
    xe = FieldElement(x, prime)
    ye = FieldElement(y, prime)
    @test_nowarn Point(xe, ye, a, b)
  end

  for (x, y) in invalidPoints
    xe = FieldElement(x, prime)
    ye = FieldElement(y, prime)
    @test_throws AssertionError Point(xe, ye, a, b)
  end

  testAddingPoints(prime, a, b, [(192, 105, 17, 56, 170, 142)])
  testAddingPoints(prime, a, b, [(170, 142, 60, 139, 220, 181), (47, 71, 17, 56, 215, 68), (143, 98, 76, 66, 47, 71)])

  @test 2 * Point(FieldElement(192, prime), FieldElement(105, prime), a, b) == Point(FieldElement(49, prime), FieldElement(71, prime), a, b)
  @test 2 * Point(FieldElement(143, prime), FieldElement(98, prime), a, b) == Point(FieldElement(64, prime), FieldElement(168, prime), a, b)
  @test 2 * Point(FieldElement(47, prime), FieldElement(71, prime), a, b) == Point(FieldElement(36, prime), FieldElement(111, prime), a, b)
  @test 4 * Point(FieldElement(47, prime), FieldElement(71, prime), a, b) == Point(FieldElement(194, prime), FieldElement(51, prime), a, b)
  @test 8 * Point(FieldElement(47, prime), FieldElement(71, prime), a, b) == Point(FieldElement(116, prime), FieldElement(55, prime), a, b)
  @test 21 * Point(FieldElement(47, prime), FieldElement(71, prime), a, b) == Point(nothing, nothing, a, b)
  @test 7 * Point(FieldElement(15, prime), FieldElement(86, prime), a, b) == Point(nothing, nothing, a, b)

end

@testset "secp256k1 class" begin
  gx = 0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798
  gy = 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8
  p = big(2)^256 - big(2)^32 - big(977)

  @test mod(gy^2, p) == mod((gx^3 + 7), p)

  x = FieldElement(gx, p)
  y = FieldElement(gy, p)
  zero = FieldElement(0, p)
  seven = FieldElement(7, p)
  g = Point(x, y, zero, seven)

  infPoint = Point(nothing, nothing, zero, seven)
  infS256Point = S256Point(nothing, nothing)

  @test isequal(infPoint, infS256Point)
  @test infPoint == infS256Point
  
  @test isequal(N*g, infPoint)
  @test isequal(N*g, infS256Point)
  @test N*g == infPoint
  @test N*g == infS256Point

  @test isequal(N*G, infPoint)
  @test isequal(N*G, infS256Point)
  @test N*G == infPoint
  @test N*G == infS256Point
end