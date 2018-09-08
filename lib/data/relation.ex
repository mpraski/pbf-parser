defmodule PBFParser.Data.Relation do
  @moduledoc """
  Struct representing a single OSM relation.

  ## Example

      %PBFParser.Data.Relation{
        id: 1843973,
        info: %PBFParser.Data.Info{
          changeset: 0,
          timestamp: #DateTime<2016-12-05 01:21:26.000Z>,
          uid: 0,
          user: "",
          version: 5,
          visible: true
        },
        members: [
          %PBFParser.Data.Member{id: 942351799, role: "admin_centre", type: :NODE},
          %PBFParser.Data.Member{id: 136822125, role: "outer", type: :WAY},
          %PBFParser.Data.Member{id: 136841179, role: "outer", type: :WAY},
          %PBFParser.Data.Member{id: 136841180, role: "outer", ...},
          %PBFParser.Data.Member{id: 136841188, ...},
          %PBFParser.Data.Member{...},
          ...
        ],
        tags: %{
          "addr:postcode" => "09220",
          "admin_level" => "8",
          "boundary" => "administrative",
          "name" => "Lercoul",
          "population" => "23",
          ...
        }
      },
  """

  defstruct id: nil,
            members: nil,
            tags: nil,
            info: nil
end
