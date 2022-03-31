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

i = 3
println(i isa Integer)

println(typeof(b""))
println(b"")

stack = (UInt8)[]
append!(stack, b"")
append!(stack, 0xff)

println(pop!(stack))
println(isempty(stack))

ss1 = Script([0x01, 0x02])
ss2 = Script([0x21, 0x22])
println(ss1)
println(ss2)

ss3 = ss1 + ss2
println(ss3)
println("ss1 ", ss1)
println("ss2 ", ss2)