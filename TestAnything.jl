using Test

include("Op.jl");  using .Op
include("Scripts.jl");  using .Scripts
include("Helper.jl");  using .Helper

s = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
c = 'A'
a = "A"

f = first(findfirst(a, s))
println(typeof(f))
println(f - 1)

ba = (UInt8)[0x00, 0x01, 0x02, 0x03, 0x04, 0x05]
println(ba[end-3:end])
println(ba[1:end-4])
