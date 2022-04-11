using Test

include("Scripts.jl");  using .Scripts
include("Helper.jl");  using .Helper

s = Script()
println(s)

s2 = Script([0x42, 0xff])
println(s2)

arr = [0x0a]
num = arr[1]
println(typeof(num), " ", num)

i = 256
println(i isa Int)
println(i in (99, 256))
