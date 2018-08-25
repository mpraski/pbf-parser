defmodule PBFParser.File do
  use Protobuf, from: Path.expand("./fileformat.proto", __DIR__)
end

defmodule PBFParser.Osm do
  use Protobuf, from: Path.expand("./osmformat.proto", __DIR__)
end
