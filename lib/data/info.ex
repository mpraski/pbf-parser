defmodule PBFParser.Data.Info do
  @moduledoc """
  Struct representing metadata optionally attached to OSM entities.
  """

  defstruct version: nil,
            uid: nil,
            timestamp: nil,
            changeset: nil,
            user: nil,
            visible: true
end
