
module Scripts

export Script, parseScript

include("Helper.jl");  using .Helper
struct Script
end

function parseScript(io::IO)::Script
  return Script()
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