
include("Transaction.jl");  using .Transaction
include("Helper.jl");  using .Helper

using Test
using Serialization

@testset "Transaction test" begin
  i1, b1 = 100, [0x64]
  i2, b2 = 255, [0xfd, 0xff, 0x00]
  i3, b3 = 555, [0xfd, 0x2b, 0x02]
  i4, b4 = 70015, [0xfe, 0x7f, 0x11, 0x01, 0x00]
  i5, b5 = 18005558675309, [0xff, 0x6d, 0xc7, 0xed, 0x3e, 0x60, 0x10, 0x00, 0x00]
  
  @test encodeVarints(i1) == b1
  @test encodeVarints(i2) == b2
  @test encodeVarints(i3) == b3
  @test encodeVarints(i4) == b4
  @test encodeVarints(i5) == b5

  fout = open("fout", "w")
  write(fout, b1)
  close(fout)
  @test decodeVarints(open("fout")) == i1

  fout = open("fout", "w")
  write(fout, b2)
  close(fout)
  @test decodeVarints(open("fout")) == i2

  fout = open("fout", "w")
  write(fout, b3)
  close(fout)
  @test decodeVarints(open("fout")) == i3

  fout = open("fout", "w")
  write(fout, b4)
  close(fout)
  @test decodeVarints(open("fout")) == i4

  fout = open("fout", "w")
  write(fout, b5)
  close(fout)
  @test decodeVarints(open("fout")) == i5
  rm("fout")

  

end

int255 = 255
big255 = BigInt(int255)
integer255 = convert(Integer, int255)
big2int = convert(UInt8, big255)
