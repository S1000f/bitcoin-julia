module Transaction
  
export Tx, TxIn, TxOut, id, hash, parseTx

struct TxIn
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
  @show serializedVersion
end

end # module