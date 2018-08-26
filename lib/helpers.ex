defmodule PBFParser.Helpers do
  def indexed_map(list) when is_list(list) do
    list |> Stream.with_index() |> Map.new(fn {v, i} -> {i, v} end)
  end

  def extract_tags(stringtable, keys, values) when is_map(stringtable) do
    keys
    |> Stream.with_index()
    |> Stream.map(fn {index, keyID} ->
      key =
        case stringtable do
          %{^keyID => value} -> value
        end

      valueID =
        case values do
          %{^index => value} -> value
        end

      value =
        case stringtable do
          %{^valueID => value} -> value
        end

      {key, value}
    end)
    |> Map.new()
  end
end
