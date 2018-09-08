defmodule PBFParser.Proto.FileFormat do
  @moduledoc false

  use Protobuf, from: Path.expand("./res/fileformat.proto", __DIR__)
end

defmodule PBFParser.Proto.OsmFormat do
  @moduledoc false

  use Protobuf, from: Path.expand("./res/osmformat.proto", __DIR__)
end
