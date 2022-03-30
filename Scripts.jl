module Scripts

export Script, parseScript, serialize

include("Helper.jl");  using .Helper

struct Script
  cmds::Vector{UInt8}

  function Script(cmds=nothing)
    new(cmds === nothing ? (UInt8)[] : cmds)
  end
end

function parseScript(s::IO)::Script
  len = decodeVarints(s)
  cmds = (UInt8)[]
  count = 0
  while count < len
    current = read(s, 1)
    count += 1
    currentByte = current[1]

    if 1 <= currentByte <= 75
      n = currentByte
      append!(cmds, read(s, n))
      count += n
    elseif currentByte == 76
      dataLength = bytes2big(read(s, 1); bigEndian=false) 
      append!(cmds, read(s, dataLength))
      count += dataLength + 1
    elseif currentByte == 77
      dataLength = bytes2big(read(s, 2); bigEndian=false) 
      append!(cmds, read(s, dataLength))
      count += dataLength + 2
    else
      opCode = currentByte
      append!(cmds, opCode)
    end
  end

  if count != len
    error("parsing script failed")
  end
  
  return Script(cmds)
end

function rawSerialize(s::Script)::Vector{UInt8}
  result = (UInt8)[]

  for cmd in s.cmds
    if cmd isa Integer
      append!(result, toByteArray(cmd, 1, bigEndian=false))
    else
      len = length(cmd)
      if len < 75
        append!(result, toByteArray(len, 1, bigEndian=false))
      elseif 75 < len < 0x100
        append!(result, toByteArray(76, 1, bigEndian=false), toByteArray(len, 1, bigEndian=false))
      elseif 0x100 <= len <= 520
        append!(result, toByteArray(77, 1, bigEndian=false), toByteArray(len, 2, bigEndian=false))
      else
        ArgumentError("too long an cmd")
      end
      append!(result, cmd)
    end
  end

  result
end

function serialize(s::Script)::Vector{UInt8}
  result = rawSerialize(s)
  total = length(result)
  append!(encodeVarints(total), result)
end

end # module