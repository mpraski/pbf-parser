defmodule PBFParser.Proto.FileFormat do
  @moduledoc """
  Decoder for PBF file format
  """

  use Protobuf, from: Path.expand("./res/fileformat.proto", __DIR__)
end

defmodule PBFParser.Proto.OsmFormat do
  @moduledoc """
  Decoder for PBF osm format
  """

  use Protobuf, from: Path.expand("./res/osmformat.proto", __DIR__)
end
