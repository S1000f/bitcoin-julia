
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

  hex_transaction = "010000000456919960ac691763688d3d3bcea9ad6ecaf875df5339e14
  8a1fc61c6ed7a069e010000006a47304402204585bcdef85e6b1c6af5c2669d4830ff86e42dd20
  5c0e089bc2a821657e951c002201024a10366077f87d6bce1f7100ad8cfa8a064b39d4e8fe4ea1
  3a7b71aa8180f012102f0da57e85eec2934a82a585ea337ce2f4998b50ae699dd79f5880e253
  dafafb7feffffffeb8f51f4038dc17e6313cf831d4f02281c2a468bde0fafd37f1bf882729e7fd
  3000000006a47304402207899531a52d59a6de200179928ca900254a36b8dff8bb75f5f5d71b1c
  dc26125022008b422690b8461cb52c3cc30330b23d574351872b7c361e9aae3649071c1a716012
  1035d5c93d9ac96881f19ba1f686f15f009ded7c62efe85a872e6a19b43c15a2937feffffff567
  bf40595119d1bb8a3037c356efd56170b64cbcc160fb028fa10704b45d775000000006a4730440
  2204c7c7818424c7f7911da6cddc59655a70af1cb5eaf17c69dadbfc74ffa0b662f02207599e08
  bc8023693ad4e9527dc42c34210f7a7d1d1ddfc8492b654a11e7620a0012102158b46fbdff65d0
  172b7989aec8850aa0dae49abfb84c81ae6e5b251a58ace5cfeffffffd63a5e6c16e620f86f375
  925b21cabaf736c779f88fd04dcad51d26690f7f345010000006a47304402200633ea0d3314bea
  0d95b3cd8dadb2ef79ea8331ffe1e61f762c0f6daea0fabde022029f23b3e9c30f080446150b23
  852028751635dcee2be669c2a1686a4b5edf304012103ffd6f4a67e94aba353a00882e563ff272
  2eb4cff0ad6006e86ee20dfe7520d55feffffff0251430f00000000001976a914ab0c0b2e98b1a
  b6dbf67d4750b0a56244948a87988ac005a6202000000001976a9143c82d7df364eb6c75be8c80
  df2b3eda8db57397088ac46430600"

txout = open("txout", "w")
serialize(txout, hex_transaction)
close(txout)
txfrom = parseTx(open("txout"))

println(txfrom)
rm("txout")

end

int255 = 255
big255 = BigInt(int255)
integer255 = convert(Integer, int255)
big2int = convert(UInt8, big255)
