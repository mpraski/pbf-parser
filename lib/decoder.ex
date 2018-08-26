defmodule PBFParser.Decoder do
  def decode_block(%Proto.Osm.PrimitiveBlock{primitivegroup: groups} = block) do
    groups |> Enum.flat_map(fn group -> decode_group(block, group) end)
  end

  def decode_group(
        block,
        %Proto.Osm.PrimitiveGroup{
          dense: dense,
          nodes: nodes,
          relations: relations,
          ways: ways
        }
      ) do
    []
    |> decode_dense(block, dense)
    |> decode_nodes(block, nodes)
    |> decode_relations(block, relations)
    |> decode_ways(block, ways)
  end

  def decompress({"OSMData", data}) do
    Proto.Osm.PrimitiveBlock.decode(:zlib.uncompress(data))
  end

  def decompress({"OSMHeader", data}) do
    Proto.Osm.HeaderBlock.decode(:zlib.uncompress(data))
  end

  defp decode_dense(
         acc,
         %Proto.Osm.PrimitiveBlock{
           date_granularity: date_granularity,
           granularity: granularity,
           lat_offset: lat_offset,
           lon_offset: lon_offset,
           stringtable: %Proto.Osm.StringTable{s: strings}
         },
         %Proto.Osm.DenseNodes{
           denseinfo: %Proto.Osm.DenseInfo{
             changeset: changeset,
             timestamp: timestamp,
             uid: uid,
             user_sid: user_sid,
             version: version,
             visible: visible
           },
           id: id,
           keys_vals: keys_vals,
           lat: lat,
           lon: lon
         }
       ) do
    [%{:kvs => extract_dense_tags(PBFParser.Helpers.indexed_map(strings), keys_vals)} | acc]
  end

  defp decode_nodes(acc, block, nodes) do
    acc
  end

  defp decode_relations(acc, block, relations) do
    acc
  end

  defp decode_ways(acc, block, ways) do
    acc
  end

  def extract_tags(stringtable, keys, values) when is_map(stringtable) do
    keys
    |> Stream.with_index()
    |> Stream.map(fn {keyID, index} ->
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

  def extract_dense_tags(stringtable, keys_vals) when is_map(stringtable) do
    extract_dense_tags(stringtable, keys_vals, []) |> Enum.reverse()
  end

  defp extract_dense_tags(_stringtable, [], acc) do
    acc
  end

  defp extract_dense_tags(stringtable, [0 | rest], acc) do
    extract_dense_tags(stringtable, rest, [%{} | acc])
  end

  defp extract_dense_tags(stringtable, [k | [v | rest]], acc) do
    {key, value} = extract_stringtable(stringtable, k, v)

    extract_dense_tags_new(stringtable, rest, %{key => value}, acc)
  end

  defp extract_dense_tags_new(stringtable, [0 | rest], new, acc) do
    extract_dense_tags(stringtable, rest, [new | acc])
  end

  defp extract_dense_tags_new(stringtable, [k | [v | rest]], new, acc) do
    {key, value} = extract_stringtable(stringtable, k, v)

    extract_dense_tags_new(stringtable, rest, Map.put(new, key, value), acc)
  end

  defp extract_stringtable(stringtable, k, v) do
    key =
      case stringtable do
        %{^k => value} -> value
      end

    value =
      case stringtable do
        %{^v => value} -> value
      end

    {key, value}
  end
end
