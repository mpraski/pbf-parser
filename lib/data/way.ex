defmodule PBFParser.Data.Way do
  @moduledoc """
  Struct representing a single OSM way.

  ## Example

      %PBFParser.Data.Way{
        id: 516715511,
        info: %PBFParser.Data.Info{
          changeset: 0,
          timestamp: #DateTime<2017-08-18 23:06:03.000Z>,
          uid: 0,
          user: "",
          version: 1,
          visible: true
        },
        refs: [5043815484, 5043815485, 5043815486, 5043815487, 5043815484],
        tags: %{
          "addr:city" => "Canillo",
          "building" => "yes",
          "tourism" => "information"
        }
      },
  """

  defstruct id: nil,
            tags: nil,
            info: nil,
            refs: nil
end
