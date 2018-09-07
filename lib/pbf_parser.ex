defmodule PBFParser do
  @moduledoc """
  Elixir parser and decoder for OpenStreetMap PBF format described in PBF file specification.
  """

  defdelegate stream(path), to: PBFParser.Reader

  defdelegate decompress_header(data), to: PBFParser.Decoder

  defdelegate decompress_block(data), to: PBFParser.Decoder

  defdelegate decode_block(block), to: PBFParser.Decoder
end
