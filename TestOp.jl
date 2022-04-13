using Test

include("Op.jl");  using .Op
include("Scripts.jl");  using .Scripts
include("Helper.jl");  using .Helper

num = 999
en = encodeNum(num)
dn = decodeNum(en)
@test en == (UInt8)[0xe7, 0x03]
@test dn == num