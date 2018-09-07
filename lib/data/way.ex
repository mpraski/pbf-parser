defmodule PBFParser.Data.Way do
  @moduledoc """
  Struct representing a single OSM way.
  """

  defstruct id: nil,
            tags: nil,
            info: nil,
            refs: nil
end
