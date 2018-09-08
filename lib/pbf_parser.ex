defmodule PBFParser do
  @moduledoc """
  Elixir parser and decoder for OpenStreetMap PBF format described in PBF file specification.
  It provides functions one can use to build their own decoder flow of .pbf files, as seen in examples.

  This module delegated functions defined in Reader and Decoder modules.

  ## Examples:
  #### With Stream
      PBFParser.stream("test.osm.pbf")
        |> Stream.drop(1)
        |> Stream.map(&PBFParser.decompress_block/1)
        |> Stream.map(&PBFParser.decode_block/1)
        |> Stream.each(&IO.inspect/1)
        |> Stream.run()
  #### With Flow
      PBFParser.stream("test.osm.pbf")
        |> Stream.drop(1)
        |> Stream.take(1_000)
        |> Flow.from_enumerable(max_demand: 50)
        |> Flow.partition(max_demand: 5, stages: 5)
        |> Flow.map(&PBFParser.decompress_block/1)
        |> Flow.partition(max_demand: 5, stages: 10)
        |> Flow.map(&PBFParser.decode_block/1)
        |> Flow.partition(window: Flow.Window.count(20))
        |> Flow.reduce(fn -> [] end, fn batch, total -> [batch | total] end)
        |> Flow.emit(:state)
        |> Flow.partition(max_demand: 5, stages: 1)
        |> Flow.each(fn item -> IO.inspect(length(item)) end)
        |> Flow.run()
  """

  defdelegate stream(path), to: PBFParser.Reader

  @doc """
  Decompresses zlib encoded blockheader data (as obtained from Reader.stream/1).

  Returns HeaderBlock, a struct generated directly from PBF protobuf specification.
  """
  defdelegate decompress_header(data), to: PBFParser.Decoder

  @doc """
  Decompresses zlib encoded block data (as obtained from Reader.stream/1).

  Returns PrimitiveBlock, a struct generated directly from PBF protobuf specification.
  """
  defdelegate decompress_block(data), to: PBFParser.Decoder

  @doc """
  Decodes the raw PrimitiveBlock (as obtained from Decoder.decompress_block/1) into a more usable format.
  Each block usually contains around 8000 densely packed node entities and a number of relation and way
  entities. Those are extracted along with accompanying metadata.

  Returns a list containing Data.Node, Data.Relation and Data.Way structs.
  """
  defdelegate decode_block(block), to: PBFParser.Decoder
end
