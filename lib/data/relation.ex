defmodule PBFParser.Data.Relation do
  @moduledoc """
  Struct representing a single OSM relation.
  """

  defstruct id: nil,
            members: nil,
            tags: nil,
            info: nil
end
