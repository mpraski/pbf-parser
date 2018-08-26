defmodule PBFParser do
  @moduledoc """
  Testing the process:

  PBFParser.start_parsing("test.osm.pbf")

  PBFParser.Reader.stream("test.osm.pbf") |> Stream.drop(1) |> Stream.map(&PBFParser.Decoder.decompress/1) |> Stream.each(fn item -> IO.inspect item.stringtable.s end) |> Stream.run()

  PBFParser.Reader.stream("test.osm.pbf") |> Stream.drop(1) |> Stream.map(&PBFParser.Decoder.decompress/1) |> Stream.each(&IO.inspect/1) |> Stream.run()
  """
end
