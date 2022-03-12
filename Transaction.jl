module Transaction
  
export Tx, TxIn, TxOut, id, hash, parseTx, parseTxIn, parseTxOut, serializeTxOut, TxFetcher, fetch, fetchTx, value, 
scriptPubKey

include("Scripts.jl");  using .Scripts
include("Helper.jl");  using .Helper
using HTTP

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

mutable struct Tx
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

function parseTx(io::IO; testnet::Bool=false)::Tx
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
  Tx(bytes2big(serializedVersion), txIns, txOuts, bytes2big(locktime), testnet=testnet)
end

function parseTxIn(io::IO)::TxIn
  prevTx = htol(read(io, 32))
  prevIndex = htol(read(io, 4))
  scriptSig = parseScript(io)
  sequence = htol(read(io, 4))
  TxIn(prevTx, bytes2big(prevIndex), scriptSig, sequence = bytes2big(sequence))
end

function parseTxOut(io::IO)::TxOut
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
  txinsArr = []
  for txin in t.txIns
    push!(txinsArr, serializeTxIn(txin))
  end
  txinBytes = append(txinsArr...)
  txOutNum = encodeVarints(length(t.txOuts))
  txoutArr = []
  for txout in t.txOuts
    push!(txoutArr, serializeTxOut(txout))
  end
  txoutBytes = append(txoutArr...)
  locktimeBytes = toByteArray(t.locktime, 4, bigEndian=false)
  append(versionBytes, txInNum, txinBytes, txOutNum, txoutBytes, locktimeBytes)
end

function hash(t::Tx)::Vector{UInt8}
  reverse(hash256(serializeTx(t)))
end

function id(t::Tx; with0x::Bool=true)::String
  bytesArr = hash(t)
  return with0x ? "0x" * bytes2hex(bytesArr) : bytes2hex(bytesArr)
end

mutable struct TxFetcher
  cache::Dict{String, Tx}
end

function getUrl(testnet::Bool=false)::String
  if testnet
    return "http://testnet.programmingbitcoin.com"
  else
    return "http://mainnet.programmingbitcoin.com"
  end
end

function fetch(t::TxFetcher, txid::String; testnet::Bool=false, fresh::Bool=false)::Tx
  if fresh || !(txid in t.cache)
    url = "$(getUrl(testnet))/tx/$(txid).hex"
    response::HTTP.Response = HTTP.get(url)
    raw = (UInt8)[]
    try
      hex = response.body
      normalized = hex[1:2] == "0x" ? hex[3:end] : hex
      raw = hex2bytes(normalized)
    catch
      UndefVarError("unexpected response: $(response.body)")
    end

    if raw[5] == 0
      raw = raw[:5] + raw[7:end]
      tx = parseTx(IOBuffer(raw), testnet=testnet)
      tx.locktime = bytes2big(reverse(raw[end-3:end]))
    else
      tx = parseTx(IOBuffer(raw), testnet=testnet)  
    end

    if id(tx) != txid
      AssertionError("not the same id: $(id(tx)) vs $(txid)")
    end

    t.cache[txid] = tx
  end

  t.cache[txid].testnet = testnet
  return t.cache[txid]
end

function fetchTx(t::TxIn; testnet::Bool=false)::Tx
  fetch(TxFetcher(Dict()), bytes2hex(t.prevTx), testnet = testnet)
end

function value(t::TxIn; testnet::Bool=false)::BigInt
  tx = fetchTx(t, testnet = testnet)
  txout = tx.txOuts[t.prevIndex + 1]
  txout.amount
end

function scriptPubKey(t::TxIn; testnet::Bool=false)::Script
  tx = fetchTx(t, testnet = testnet)
  txout = tx.txOuts[t.prevIndex + 1]
  txout.scriptPubKey
end

end # module