module Transaction
  
export Tx, TxIn, TxOut, id, hash, parseTx

include("Scripts.jl");  using .Scripts
include("Helper.jl");  using .Helper

struct TxIn
  prevTx::Vector{UInt8}
  prevIndex::UInt32
  scriptSig::Script
  sequence::UInt32

  function TxIn(prevTx::Vector{UInt8}, prevIndex::UInt32, scriptSig::Script=nothing; sequence::UInt32=0xffffffff)
    script
    if scriptSig === nothing
      script = Script()
    else
      script = scriptSig
    end
    new(prevTx, prevIndex, script, sequence)
  end
end

function Base.show(io::IO, t::TxIn)
  print(io, "$(bytes2hex(t.prevTx)):$(t.prevIndex)")  
end

struct TxOut
end

struct Tx
  version
  txIns::Vector{TxIn}
  txOuts::Vector{TxOut}
  locktime
  testnet::Bool

  function Tx(version, txIns, txOuts, locktime; testnet::Bool=false)
    new(version, txIns, txOuts, locktime, testnet)
  end
end

function Base.show(io::IO, t::Tx)
  print(io, t)
end

function id(t::Tx)
  
end

function hash(t::Tx)
  
end

function parseTx(io::IOStream)
  serializedVersion = htol(read(io, 4))
  numInputs = decodeVarints(io)
  txIns = (TxIn)[]
  for i in 1:numInputs
    append!(txIns, parseTxIn(io))
  end



  @show serializedVersion
end

function parseTxIn(io::IOStream)::TxIn
  prevTx = htol(read(io, 32))
  prevIndex = htol(read(io, 4))
  scriptSig = parseScript(io)
  sequence = read(io, 4)
  TxIn(prevTx, prevIndex, scriptSig, sequence = sequence)
end

end # module