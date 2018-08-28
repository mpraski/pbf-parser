defmodule PBFParser.Decoder do
  @empty_dense_info %Proto.Osm.DenseInfo{
    changeset: [],
    timestamp: [],
    uid: [],
    user_sid: [],
    version: [],
    visible: []
  }

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
    cond do
      dense -> decode_dense(block, dense)
      length(nodes) > 0 -> decode_nodes(block, nodes)
      length(relations) > 0 -> decode_relations(block, relations)
      length(ways) > 0 -> decode_ways(block, ways)
    end
  end

  def decompress_block(data) do
    Proto.Osm.PrimitiveBlock.decode(:zlib.uncompress(data))
  end

  def decompress_header(data) do
    Proto.Osm.HeaderBlock.decode(:zlib.uncompress(data))
  end

  defp decode_dense(
         block,
         %Proto.Osm.DenseNodes{
           denseinfo: nil
         } = dense
       ) do
    decode_dense(block, %Proto.Osm.DenseNodes{
      dense
      | denseinfo: @empty_dense_info
    })
  end

  defp decode_dense(
         %Proto.Osm.PrimitiveBlock{
           date_granularity: date_granularity,
           granularity: granularity,
           lat_offset: lat_offset,
           lon_offset: lon_offset,
           stringtable: stringtable
         },
         %Proto.Osm.DenseNodes{
           id: ids,
           keys_vals: keys_vals,
           lat: lats,
           lon: lons,
           denseinfo: %Proto.Osm.DenseInfo{
             changeset: changesets,
             timestamp: timestamps,
             uid: uids,
             user_sid: user_sids,
             version: versions,
             visible: visibles
           }
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
      {[], 0, 0, 0, 0, 0, 0, 0},
      fn {id, lat, lon, tagmap, changeset, timestamp, uid, user_sid, version, visible},
         {acc, ida, lata, lona, timestampa, changeseta, uida, user_sida} ->
        id = ida + id
        lat = lata + lat
        lon = lona + lon

        changeset = if changeset, do: changeseta + changeset
        timestamp = if timestamp, do: timestampa + timestamp
        uid = if uid, do: uida + uid
        user_sid = if user_sid, do: user_sida + user_sid

        {[
           %Data.Node{
             id: id,
             latitude: 1.0e-9 * (lat_offset + granularity * lat),
             longitude: 1.0e-9 * (lon_offset + granularity * lon),
             tags: tagmap,
             info: %Data.Info{
               changeset: changeset,
               timestamp: get_date(timestamp, date_granularity),
               uid: uid,
               user: get_user(user_sid, stringtable),
               version: version,
               visible: visible
             }
           }
           | acc
         ], id, lat, lon, timestamp, changeset, uid, user_sid}
      end
    )
    |> elem(0)
  end

  defp decode_nodes(
         %Proto.Osm.PrimitiveBlock{
           date_granularity: date_granularity,
           granularity: granularity,
           lat_offset: lat_offset,
           lon_offset: lon_offset,
           stringtable: stringtable
         },
         nodes
       ) do
    nodes
    |> Enum.map(fn %Proto.Osm.Node{
                     id: id,
                     keys: keys,
                     vals: vals,
                     lat: lat,
                     lon: lon,
                     info: info
                   } ->
      %Data.Node{
        id: id,
        latitude: 1.0e-9 * (lat_offset + granularity * lat),
        longitude: 1.0e-9 * (lon_offset + granularity * lon),
        tags: extract_tags(stringtable, keys, vals),
        info: extract_info(stringtable, date_granularity, info)
      }
    end)
  end

  defp decode_relations(block, relations) do
    []
  end

  defp decode_ways(
         %Proto.Osm.PrimitiveBlock{
           date_granularity: date_granularity,
           stringtable: stringtable
         },
         ways
       ) do
    ways
    |> Enum.map(fn %Proto.Osm.Way{
                     id: id,
                     keys: keys,
                     vals: vals,
                     refs: refs,
                     info: info
                   } ->
      %Data.Way{
        id: id,
        tags: extract_tags(stringtable, keys, vals),
        refs: extract_refs(refs),
        info: extract_info(stringtable, date_granularity, info)
      }
    end)
  end

  defp extract_info(_, _, nil) do
    nil
  end

  defp extract_info(
         stringtable,
         date_granularity,
         %Proto.Osm.Info{
           changeset: changeset,
           timestamp: timestamp,
           uid: uid,
           user_sid: user_sid,
           version: version,
           visible: visible
         }
       ) do
    %Data.Info{
      changeset: changeset,
      timestamp: get_date(timestamp, date_granularity),
      uid: uid,
      user: get_user(user_sid, stringtable),
      version: version,
      visible: visible
    }
  end

  defp extend(list, base) do
    list |> Stream.concat(Stream.repeatedly(fn -> base end))
  end

  defp get_date(timestamp, date_granularity) do
    case DateTime.from_unix(timestamp * date_granularity, :millisecond) do
      {:ok, date} -> date
      {:error, _reason} -> nil
    end
  end

  defp get_user(user_sid, stringtable) do
    if user_sid do
      :array.get(user_sid, stringtable)
    end
  end

  defp extract_refs(refs) do
    extract_refs(refs, [], 0)
  end

  defp extract_refs([], decoded, _acc) do
    decoded |> Enum.reverse()
  end

  defp extract_refs([ref | rest], decoded, acc) do
    next = ref + acc

    extract_refs(rest, [next | decoded], next)
  end

  defp extract_tags(stringtable, keys, vals) do
    [
      keys,
      vals
    ]
    |> Stream.zip()
    |> Stream.map(fn {k, v} ->
      key = :array.get(k, stringtable)
      value = :array.get(v, stringtable)

      {key, value}
    end)
    |> Map.new()
  end

  defp extract_dense_tags(stringtable, keys_vals) do
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
