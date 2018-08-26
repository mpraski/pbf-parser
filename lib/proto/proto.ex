defmodule Proto.File do
  use Protobuf, from: Path.expand("./fileformat.proto", __DIR__)
end

defmodule Proto.Osm do
  use Protobuf, from: Path.expand("./osmformat.proto", __DIR__)
end
