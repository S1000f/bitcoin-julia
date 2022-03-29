module Scripts

export Script, parseScript

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

function serializeScriptSig(s::Script)::Vector{UInt8}
  # TODO:
  toByteArray(0x42)
end

function serializeScriptPubKey(s::Script)::Vector{UInt8}
  # TODO:
  toByteArray(0x42)
end

end # module