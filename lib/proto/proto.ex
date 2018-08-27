defmodule Proto.File do
  use Protobuf, from: Path.expand("./res/fileformat.proto", __DIR__)
end

defmodule Proto.Osm do
  use Protobuf, from: Path.expand("./res/osmformat.proto", __DIR__)
end
