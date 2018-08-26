defmodule PBFParser.Decoder do
  def decode_header(header) do
  end

  def decode_data(data) do
  end

  def decompress({type, data}) do
    zlib_uncompressed = :zlib.uncompress(data)

    case type do
      "OSMHeader" ->
        Proto.Osm.HeaderBlock.decode(zlib_uncompressed)

      "OSMData" ->
        Proto.Osm.PrimitiveBlock.decode(zlib_uncompressed)
    end
  end
end
