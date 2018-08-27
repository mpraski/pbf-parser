defmodule PBFParser.Decoder do
  def decode_block(
        %Proto.Osm.PrimitiveBlock{
          primitivegroup: groups,
          stringtable: %Proto.Osm.StringTable{s: stringtable}
        } = primitive_block
      ) do
    groups
    |> Enum.flat_map(fn group ->
      decode_group(
        %Proto.Osm.PrimitiveBlock{
          primitive_block
          | stringtable: stringtable |> :array.from_list()
        },
        group
      )
    end)
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

  def decompress_block(data) do
    Proto.Osm.PrimitiveBlock.decode(:zlib.uncompress(data))
  end

  def decompress_header(data) do
    Proto.Osm.HeaderBlock.decode(:zlib.uncompress(data))
  end

  defp decode_dense(
         acc,
         %Proto.Osm.PrimitiveBlock{
           date_granularity: date_granularity,
           granularity: granularity,
           lat_offset: lat_offset,
           lon_offset: lon_offset,
           stringtable: stringtable
         },
         %Proto.Osm.DenseNodes{
           denseinfo: %Proto.Osm.DenseInfo{
             changeset: changesets,
             timestamp: timestamps,
             uid: uids,
             user_sid: user_sids,
             version: versions,
             visible: visibles
           },
           id: ids,
           keys_vals: keys_vals,
           lat: lats,
           lon: lons
         }
       ) do
    tags = extract_dense_tags(stringtable, keys_vals)

    Enum.concat(
      [
        ids,
        lats,
        lons,
        tags
      ],
      [
        changesets,
        timestamps,
        uids,
        user_sids,
        versions,
        visibles
      ]
      |> Enum.map(fn set -> set |> extend(nil) end)
    )
    |> Stream.zip()
    |> Enum.reduce(
      {acc, 0, 0, 0, 0, 0, 0, 0},
      fn {id, lat, lon, tagmap, changeset, timestamp, uid, user_sid, version, visible},
         {acc, ida, lata, lona, timestampa, changeseta, uida, user_sida} ->
        id = ida + id
        lat = lata + lat
        lon = lona + lon

        timestamp =
          if timestamp do
            timestampa + timestamp
          end

        changeset =
          if changeset do
            changeseta + changeset
          end

        uid =
          if uid do
            uida + uid
          end

        user_sid =
          if user_sid do
            user_sida + user_sid
          end

        user =
          if user_sid do
            :array.get(user_sid, stringtable)
          end

        timestamp_date =
          case DateTime.from_unix(timestamp * date_granularity, :millisecond) do
            {:ok, date} -> date
            {:error, _reason} -> nil
          end

        {[
           %Data.Node{
             id: id,
             latitude: 1.0e-9 * (lat_offset + granularity * lat),
             longitude: 1.0e-9 * (lon_offset + granularity * lon),
             tags: tagmap,
             info: %Data.Info{
               version: version,
               uid: uid,
               timestamp: timestamp_date,
               changeset: changeset,
               user: user,
               visible: visible
             }
           }
           | acc
         ], id, lat, lon, timestamp, changeset, uid, user_sid}
      end
    )
    |> elem(0)
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

  defp extend(list, base) do
    list |> Stream.concat(Stream.repeatedly(fn -> base end))
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

  @doc """
  Builds a tag map for consequtive nodes encodes encoded in dense format.
  See https://wiki.openstreetmap.org/wiki/PBF_Format#Nodes
  """
  def extract_dense_tags(stringtable, keys_vals) do
    stringtable |> extract_dense_tags(keys_vals, []) |> Enum.reverse()
  end

  defp extract_dense_tags(_stringtable, [], acc) do
    acc
  end

  defp extract_dense_tags(stringtable, [0 | rest], acc) do
    stringtable |> extract_dense_tags(rest, [nil | acc])
  end

  defp extract_dense_tags(stringtable, [k | [v | rest]], acc) do
    key = :array.get(k, stringtable)
    value = :array.get(v, stringtable)

    stringtable |> extract_dense_tags_for_node(rest, %{key => value}, acc)
  end

  defp extract_dense_tags_for_node(stringtable, [0 | rest], node, acc) do
    stringtable |> extract_dense_tags(rest, [node | acc])
  end

  defp extract_dense_tags_for_node(stringtable, [k | [v | rest]], node, acc) do
    key = :array.get(k, stringtable)
    value = :array.get(v, stringtable)

    stringtable |> extract_dense_tags_for_node(rest, node |> Map.put(key, value), acc)
  end
end
