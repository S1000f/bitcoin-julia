using Test

include("Op.jl");  using .Op
include("Scripts.jl");  using .Scripts
include("Helper.jl");  using .Helper

num = 999
en = encodeNum(num)
dn = decodeNum(en)
@test en == (UInt8)[0xe7, 0x03]
@test dn == num

stack = (Any)[9, 9]
equalverify = OP_CODE_FUNCTIONS[136]
@test equalverify(stack)

arr = (Any)[0x01, 0x02, 0x03, [0x04, 0x05], [0x43, 0x44]]
println("original ", arr)

p1 = popat!(arr, length(arr) - 1)
println(p1)
push!(arr, p1)
println(arr)
