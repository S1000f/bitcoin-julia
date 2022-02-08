using Test
using Random
using SHA
include("ecc.jl");  using .Ecc
include("Helper.jl");  using .Helper

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

@testset "ECDSA" begin
  z = 0xbc62d4b80d9e36da29c16c5d4d9f11731f36052c72401a76c23c0fb5a9b74423
  r = 0x37206a0610995c58074999cb9767b87af4c4978db68c06e8e6e81d282047a7c6
  s = 0x8ca63759c1157ebeaec0d03cecca119fc9a75bf8e6d0fa65c841c8e2738cdaec
  px = 0x04519fac3d910ca7e7138f7013706f619fa8f033e6ec6e09370ea38cee6a7574
  py = 0x82b51eab8c27c66e26c858a079bcdf4f1ada34cec420cafc7eac1a42216fb6c4
  point = S256Point(px, py)
  s_inv = powermod(s, N - 2, N)
  u = z * mod(s_inv, N)
  v = r * mod(s_inv, N)

  @test (u * G + v * point).x.num == r
  @test verify(point, z, Signature(r, s))
end

@testset "Helper test" begin
  e = hash256toBigInt("my secret")
  z = hash256toBigInt("my message")
  k = 1234567890
  r = (k * G).x.num
  kInv = powermod(k, N - 2, N)
  s = mod(((z + r * e) * kInv), N)
  point = e * G

  @test z == 0x231c6f3d980a6b0fb7152f85cee7eb52bf92433d9919b9c5218cb08e79cce78
  @test r == 0x2b698a0f0a4041b77e63488ad48c23e8e8838dd1fb7520408b121697b782ef22
  @test s == 0xbb14e602ef9e3f872e25fad328466b34e6734b7a0fcd58b1eb635447ffae8cb9

  kRand = rand(0:N)

  kk = b"\x00"
  parsed = parse(UInt8, bytes2hex(kk))
  arr = Array([parsed, parsed, parsed, parsed])
  cue = codeunits(big2hex(e))

  println(arr)
  println(cue)

  for unit in cue
    push!(arr, unit)
  end

  println(arr)

  digested = hmac_sha256(collect(codeunits(bytes2hex(b"\x00"))), big2hex(e))
  digested2 = hmac_sha256(arr, big2hex(e))
  hmac_sha256(digested, arr)


end