defmodule PBFParser.Helpers do
  def indexed_map(list) when is_list(list) do
    list |> Stream.with_index() |> Map.new(fn {v, i} -> {i, v} end)
  end
end
