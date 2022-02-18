module Transaction
  
export Tx, TxIn, TxOut, id, hash, parseTx, parseTxIn, parseTxOut, serializeTxOut

include("Scripts.jl");  using .Scripts
include("Helper.jl");  using .Helper

struct TxIn
  prevTx::Vector{UInt8}
  prevIndex::UInt32
  scriptSig::Script
  sequence::UInt32

  function TxIn(prevTx::Vector{UInt8}, prevIndex::Integer, scriptSig::Script=nothing; sequence::Integer=0xffffffff)
    script = scriptSig === nothing ? Script() : scriptSig
    new(prevTx, prevIndex, script, sequence)
  end
end

function Base.show(io::IO, t::TxIn)
  print(io, "$(bytes2hex(t.prevTx)):$(t.prevIndex)")  
end

struct TxOut
  amount::BigInt
  scriptPubKey::Script

  function TxOut(amount::BigInt, scriptPubKey::Script)
    new(amount, scriptPubKey)
  end
end

function Base.show(io::IO, t::TxOut)
  print(io, "$(t.amount):$(t.scriptPubKey)")
end

struct Tx
  version::UInt32
  txIns::Vector{TxIn}
  txOuts::Vector{TxOut}
  locktime::UInt32
  testnet::Bool

  function Tx(version::Integer, txIns::Vector{TxIn}, txOuts::Vector{TxOut}, locktime::Integer; testnet::Bool=false)
    new(version, txIns, txOuts, locktime, testnet)
  end
end

function Base.show(io::IO, t::Tx)
  txInString = ""
  for item in t.txIns
    txInString *= "$(bytes2hex(item.prevTx)):$(item.prevIndex)\n"
  end
  txOutString = ""
  for item in t.txOuts
    txOutString *= "$(item.amount):$(item.scriptPubKey)\n"
  end
  print(io, "tx: \nversion: $(t.version)\ntx_ins:\n$(txInString)tx_out:\n$(txOutString)locktime: $(t.locktime)")
end

function id(t::Tx)
  
end

function hash(t::Tx)
  
end

function parseTx(io::IOStream)::Tx
  serializedVersion = htol(read(io, 4))
  numInputs = decodeVarints(io)
  txIns = (TxIn)[]
  for i in 1:numInputs
    push!(txIns, parseTxIn(io))
  end
  numOutouts = decodeVarints(io)
  txOuts = (TxOut)[]
  for i in 1:numOutouts
    push!(txOuts, parseTxOut(io))
  end
  locktime = htol(read(io, 4))
  Tx(bytes2big(serializedVersion), txIns, txOuts, bytes2big(locktime))
end

function parseTxIn(io::IOStream)::TxIn
  prevTx = htol(read(io, 32))
  prevIndex = htol(read(io, 4))
  scriptSig = parseScript(io)
  sequence = htol(read(io, 4))
  TxIn(prevTx, bytes2big(prevIndex), scriptSig, sequence = bytes2big(sequence))
end

function parseTxOut(io::IOStream)::TxOut
  amount = htol(read(io, 8))
  scriptPubKey = parseScript(io)
  TxOut(bytes2big(amount), scriptPubKey)
end

"""
returns the byte serialization of the transaction output
"""
function serializeTxOut(t::TxOut)::Vector{UInt8}
  amountBytes = toByteArray(t.amount, 8, bigEndian=false)
  scriptPubKeyBytes = serializeScriptPubKey(t.scriptPubKey)
  append(amountBytes, scriptPubKeyBytes)
end

"""
returns the byte serialization of the transaction numInputs
"""
function serializeTxIn(t::TxIn)::Vector{UInt8}
  append(reverse(t.prevTx), toByteArray(t.prevIndex, 4, bigEndian=false), serializeScriptSig(t.scriptSig), 
    toByteArray(t.sequence, 4, bigEndian=false))
end

"""
returns the byte serialization of the transaction
"""
function serializeTx(t::Tx)::Vector{UInt8}
  versionBytes = toByteArray(t.version, 4, bigEndian=false)
  txInNum = encodeVarints(length(t.txIns))
  
  for txin in t.txIns
    serializeTxIn(txin)
end

end # module