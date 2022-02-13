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
end

@testset "serialization test" begin
  e1 = 5000
  e2 = 2018^5
  e3 = 0xdeadbeef12345
  p1 = e1 * G
  p2 = e2 * G
  p3 = e3 * G
  sec1 = serializeBySEC(p1, compressed = false)
  sec2 = serializeBySEC(p2, compressed = false)
  sec3 = serializeBySEC(p3, compressed = false)

  ans1 = 0x04ffe558e388852f0120e46af2d1b370f85854a8eb0841811ece0e3e03d282d57c315dc72890a4f10a1481c031b03b351b0dc79901ca18a00cf009dbdb157a1d10
  ans2 = 0x04027f3da1918455e03c46f659266a1bb5204e959db7364d2f473bdf8f0a13cc9dff87647fd023c13b4a4994f17691895806e1b40b57f4fd22581a4f46851f3b06
  ans3 = 0x04d90cd625ee87dd38656dd95cf79f65f60f7273b67d3096e68bd81e4f5342691f842efa762fd59961d0e99803c61edba8b3e3f7dc3a341836f97733aebf987121

  @test bytes2big(sec1) == ans1
  @test bytes2big(sec2) == ans2
  @test bytes2big(sec3) == ans3

  pk1 = PrivateKey(5001)
  pk2 = PrivateKey(2019^5)
  pk3 = PrivateKey(0xdeadbeef54321)
  secpk1 = serializeBySEC(pk1.point)
  secpk2 = serializeBySEC(pk2.point)
  secpk3 = serializeBySEC(pk3.point)
  pk1sechex = bytes2hex(secpk1)
  pk2sechex = bytes2hex(secpk2)
  pk3sechex = bytes2hex(secpk3)

  anspk1 = "0357a4f368868a8a6d572991e484e664810ff14c05c0fa023275251151fe0e53d1"
  anspk2 = "02933ec2d2b111b92737ec12f1c5d20f3233a0ad21cd8b36d0bca7a0cfa5cb8701"
  anspk3 = "0296be5b1292f6c856b3c5654e886fc13511462059089cdf9c479623bfcbe77690"

  @test pk1sechex == anspk1
  @test pk2sechex == anspk2
  @test pk3sechex == anspk3

  p1parsed = parseSEC(sec1)
  p2parsed = parseSEC(sec2)
  p3parsed = parseSEC(sec3)

  @test(p1 == p1parsed)
  @test(isequal(p2, p2parsed))
  @test(isequal(p3, p3parsed))

  pk1parsed = parseSEC(secpk1)
  @test pk1.point == pk1parsed

  pk2parsed = parseSEC(secpk2)
  @test pk2.point == pk2parsed

  pk3parsed = parseSEC(secpk3)
  @test pk3.point == pk3parsed

  r = 0x37206a0610995c58074999cb9767b87af4c4978db68c06e8e6e81d282047a7c6
  s = 0x8ca63759c1157ebeaec0d03cecca119fc9a75bf8e6d0fa65c841c8e2738cdaec
  ans = "3045022037206a0610995c58074999cb9767b87af4c4978db68c06e8e6e81d282047a7c60221008ca63759c1157ebeaec0d03cecca119fc9a75bf8e6d0fa65c841c8e2738cdaec"

  sig = Signature(r, s)
  der = serializeByDER(sig)
  @test bytes2hex(der) == ans

  b1 = 0x7c076ff316692a3d7eb3c3bb0f8b1488cf72e1afcd929e29307032997a838a3d
  b2 = 0xeff69ef2b1bd93a66ed5219add4fb51e11a840f404876325a1e8ffe0529a2c
  b3 = 0xc7207fee197d27c618aea621406f6bf5ef6fca38681d82b2f06fddbdce6feab6

  ansb1 = "9MA8fRQrT4u8Zj8ZRd6MAiiyaxb2Y1CMpvVkHQu5hVM6"
  ansb2 = "4fE3H2E6XMp4SsxtwinF7w9a34ooUrwWe4WsW1458Pd"
  ansb3 = "EQJsjkd6JaGwxrjEhfeqPenqHwrBmPQZjJGNSCHBkcF7"

  @test base58(b1) == ansb1
  @test base58(b2) == ansb2
  @test base58(b3) == ansb3

  priv1 = PrivateKey(5002)
  priv2 = PrivateKey(2020^5)
  priv3 = PrivateKey(0x12345deadbeef)
  
  addr1 = address(priv1.point, compressed = false, testnet = true)
  addr2 = address(priv2.point, compressed = true, testnet = true)
  addr3 = address(priv3.point, compressed = true, testnet = false)
  
  ansaddr1 = "mmTPbXQFxboEtNRkwfh6K51jvdtHLxGeMA"
  ansaddr2 = "mopVkxp8UhXqRYbCYJsbeE1h1fiF64jcoH"
  ansaddr3 = "1F1Pn2y6pDb68E5nYJJeba4TLg2U7B6KF1"
  
  @test (addr1 == ansaddr1)
  @test (addr2 == ansaddr2)
  @test (addr3 == ansaddr3)

  pv1 = PrivateKey(5003)
  pv2 = PrivateKey(2021^5)
  pv3 = PrivateKey(0x54321deadbeef)
  
  answif1 = "cMahea7zqjxrtgAbB7LSGbcQUr1uX1ojuat9jZodMN8rFTv2sfUK"
  answif2 = "91avARGdfge8E4tZfYLoxeJ5sGBdNJQH4kvjpWAxgzczjbCwxic"
  answif3 = "KwDiBf89QgGbjEhKnhXJuH7LrciVrZi3qYjgiuQJv1h8Ytr2S53a"
  
  @test wif(pv1; testnet = true) == answif1
  @test wif(pv2; compressed = false, testnet = true) == answif2
  @test wif(pv3) == answif3

  int266 = 266
  barr = toByteArray(int266, bigEndian = false)
  bbb = bytes2big(barr, bigEndian = false)
  @test (int266 == bbb)

end
