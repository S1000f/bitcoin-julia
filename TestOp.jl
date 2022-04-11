using Test

include("Op.jl");  using .Op
include("Scripts.jl");  using .Scripts
include("Helper.jl");  using .Helper

opdup = OP_CODE_FUNCTIONS[118]

stack1 = (Any)[]
push!(stack1, 0x42)
push!(stack1, b"")

println(stack1)

println(opdup(stack1))

println(stack1)