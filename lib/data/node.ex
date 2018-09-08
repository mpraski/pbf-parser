defmodule PBFParser.Data.Node do
  @moduledoc """
  Struct representing a single OSM node.

  ## Example

      %PBFParser.Data.Node{
        id: 112313935,
        info: %PBFParser.Data.Info{
          changeset: 0,
          timestamp: #DateTime<2007-11-13 21:13:29.000Z>,
          uid: 0,
          user: "",
          version: 1,
          visible: nil
        },
        latitude: 9.438089900000001,
        longitude: -78.59363,
        tags: %{"created_by" => "JOSM"}
      }
  """

  defstruct id: nil,
            latitude: nil,
            longitude: nil,
            tags: nil,
            info: nil
end
