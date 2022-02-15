
include("Transaction.jl");  using .Transaction
include("Helper.jl");  using .Helper

using Test

@testset "Transaction test" begin
  @test encodeVarints(100) == [0x64]
  @test encodeVarints(255) == [0xfd, 0xff, 0x00]
  @test encodeVarints(555) == [0xfd, 0x2b, 0x02]
  @test encodeVarints(70015) == [0xfe, 0x7f, 0x11, 0x01, 0x00]
  @test encodeVarints(BigInt(18005558675309)) = [0xff, 0x6d, 0xc7, 0xed, 0x3e, 0x60, 0x10, 0x00, 0x00]
end

io = open("ex")

r1 = read(io, 1)
r2 = read(io, 2)
println(r1)
println(r2)

r11 = r1[1]
println(typeof(r11))
println(r11)

br1 = bytes2big(r1)
println(typeof(br1))
println(br1)

hr1 = bytes2hex(r1)
println(typeof(hr1))
println(hr1)

println(r1 == 0x61)
println(r11 == 0x61)
println(br1 == 0x61)
println(hr1 == 0x61)

close(io)

int255 = 200

big255 = BigInt(int255)
println(typeof(big255))
println(big255)

integer255 = convert(Integer, int255)
println(typeof(integer255))
println(integer255)

big2int = convert(UInt8, big255)
println(typeof(big2int))
println(big2int)
println(isa(big255, Integer))

println(big255 < 0x10000000000000000)

