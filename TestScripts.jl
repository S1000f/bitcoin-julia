using Test

include("Scripts.jl");  using .Scripts
include("Helper.jl");  using .Helper

s = Script()
println(s)

s2 = Script([0x42, 0xff])
println(s2)

i = 256
println(i isa Int)
println(i in (99, 256))

arr = (Any)[]
push!(arr, b"")
push!(arr, 0x42)
println(typeof(arr))
println(arr)