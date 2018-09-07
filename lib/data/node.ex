defmodule PBFParser.Data.Node do
  @moduledoc """
  Struct representing a single OSM node.
  """

  defstruct id: nil,
            latitude: nil,
            longitude: nil,
            tags: nil,
            info: nil
end
