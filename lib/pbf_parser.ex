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

  defdelegate decompress_header(data), to: PBFParser.Decoder

  defdelegate decompress_block(data), to: PBFParser.Decoder

  defdelegate decode_block(block), to: PBFParser.Decoder
end
