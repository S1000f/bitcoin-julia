arr = [0x0a, 0x01, 0x02]
io = IOBuffer(arr)

r1 = read(io, 1)
println(r1)
n = r1[1]
println(n)

println(n == 0x0a)