defmodule PBFParser.Decoder do
  @moduledoc false

  alias PBFParser.Proto.OsmFormat.{
    DenseInfo,
    DenseNodes,
    HeaderBlock,
    Info,
    Node,
    PrimitiveBlock,
    PrimitiveGroup,
    Relation,
    StringTable,
    Way
  }

  @empty_dense_info %DenseInfo{
    changeset: [],
    timestamp: [],
    uid: [],
    user_sid: [],
    version: [],
    visible: []
  }

  @spec decompress_block(iodata()) :: PrimitiveBlock.t()
  def decompress_block(data) do
    PrimitiveBlock.decode(:zlib.uncompress(data))
  end

  @spec decompress_header(iodata()) :: HeaderBlock.t()
  def decompress_header(data) do
    HeaderBlock.decode(:zlib.uncompress(data))
  end

  @spec decode_block(PrimitiveBlock.t()) :: [Data.Node.t() | Data.Relation.t() | Data.Way.t()]
  def decode_block(
        %PrimitiveBlock{
          primitivegroup: groups,
          stringtable: %StringTable{s: stringtable}
        } = primitive_block
      ) do
    groups
    |> Enum.flat_map(fn group ->
      decode_group(
        %PrimitiveBlock{
          primitive_block
          | stringtable: stringtable |> :array.from_list()
        },
        group
      )
    end)
  end

  defp decode_group(
         block,
         %PrimitiveGroup{
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

  defp decode_dense(
         block,
         %DenseNodes{
           denseinfo: nil
         } = dense
       ) do
    decode_dense(block, %DenseNodes{dense | denseinfo: @empty_dense_info})
  end

  #################################################
  # Decode densely encoded nodes. This            #
  # requires reducing a collection of lists       #
  # from DenseNodes struct, as well as extracting #
  # tags for each node (lazily).                  #
  #################################################

  defp decode_dense(
         %PrimitiveBlock{
           date_granularity: date_granularity,
           granularity: granularity,
           lat_offset: lat_offset,
           lon_offset: lon_offset,
           stringtable: stringtable
         },
         %DenseNodes{
           id: ids,
           keys_vals: keys_vals,
           lat: lats,
           lon: lons,
           denseinfo: %DenseInfo{
             changeset: changesets,
             timestamp: timestamps,
             uid: uids,
             user_sid: user_sids,
             version: versions,
             visible: visibles
           }
         }
       ) do
    tags = stringtable |> extract_dense_tags(keys_vals)

    values = [
      ids,
      lats,
      lons,
      tags
    ]

    extended_values =
      [
        changesets,
        timestamps,
        uids,
        user_sids,
        versions,
        visibles
      ]
      |> Stream.map(&extend/1)

    [
      values,
      extended_values
    ]
    |> Stream.concat()
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
           %PBFParser.Data.Node{
             id: id,
             latitude: 1.0e-9 * (lat_offset + granularity * lat),
             longitude: 1.0e-9 * (lon_offset + granularity * lon),
             tags: tagmap,
             info: %PBFParser.Data.Info{
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
         %PrimitiveBlock{
           date_granularity: date_granularity,
           granularity: granularity,
           lat_offset: lat_offset,
           lon_offset: lon_offset,
           stringtable: stringtable
         },
         nodes
       ) do
    nodes
    |> Enum.map(fn %Node{
                     id: id,
                     keys: keys,
                     vals: vals,
                     lat: lat,
                     lon: lon,
                     info: info
                   } ->
      %PBFParser.Data.Node{
        id: id,
        latitude: 1.0e-9 * (lat_offset + granularity * lat),
        longitude: 1.0e-9 * (lon_offset + granularity * lon),
        tags: extract_tags(stringtable, keys, vals),
        info: extract_info(stringtable, date_granularity, info)
      }
    end)
  end

  defp decode_relations(
         %PrimitiveBlock{
           date_granularity: date_granularity,
           stringtable: stringtable
         },
         relations
       ) do
    relations
    |> Enum.map(fn %Relation{
                     id: id,
                     keys: keys,
                     vals: vals,
                     info: info,
                     roles_sid: roles_sid,
                     memids: memids,
                     types: types
                   } ->
      %PBFParser.Data.Relation{
        id: id,
        members: extract_members(stringtable, roles_sid, memids, types),
        tags: extract_tags(stringtable, keys, vals),
        info: extract_info(stringtable, date_granularity, info)
      }
    end)
  end

  defp decode_ways(
         %PrimitiveBlock{
           date_granularity: date_granularity,
           stringtable: stringtable
         },
         ways
       ) do
    ways
    |> Enum.map(fn %Way{
                     id: id,
                     keys: keys,
                     vals: vals,
                     refs: refs,
                     info: info
                   } ->
      %PBFParser.Data.Way{
        id: id,
        tags: extract_tags(stringtable, keys, vals),
        refs: extract_refs(refs),
        info: extract_info(stringtable, date_granularity, info)
      }
    end)
  end

  #######################################
  # Stream specified base element after #
  # traversing a list                   #
  #######################################

  defp extend(list, base \\ nil) do
    list |> Stream.concat(Stream.repeatedly(fn -> base end))
  end

  defp get_date(timestamp, date_granularity) do
    if timestamp do
      case DateTime.from_unix(timestamp * date_granularity, :millisecond) do
        {:ok, date} -> date
        {:error, _reason} -> nil
      end
    end
  end

  defp get_user(user_sid, stringtable) do
    if user_sid do
      :array.get(user_sid, stringtable)
    end
  end

  ##################################
  # Extract common data structures #
  ##################################

  defp extract_info(_, _, nil), do: nil

  defp extract_info(
         stringtable,
         date_granularity,
         %Info{
           changeset: changeset,
           timestamp: timestamp,
           uid: uid,
           user_sid: user_sid,
           version: version,
           visible: visible
         }
       ) do
    %PBFParser.Data.Info{
      changeset: changeset,
      timestamp: get_date(timestamp, date_granularity),
      uid: uid,
      user: get_user(user_sid, stringtable),
      version: version,
      visible: if(visible != nil, do: visible, else: true)
    }
  end

  defp extract_members(strintable, roles_sids, memids, types) do
    [
      roles_sids,
      memids,
      types
    ]
    |> Stream.zip()
    |> Enum.reduce(
      {[], 0},
      fn {roles_sid, memid, type}, {acc, memida} ->
        memid = memid + memida

        {[
           %PBFParser.Data.Member{
             id: memid,
             type: type,
             role: :array.get(roles_sid, strintable)
           }
           | acc
         ], memid}
      end
    )
    |> elem(0)
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
    Stream.resource(
      fn -> keys_vals end,
      fn
        [] ->
          {:halt, nil}

        [0 | rest] ->
          {[nil], rest}

        [k | [v | rest]] ->
          key = :array.get(k, stringtable)
          value = :array.get(v, stringtable)

          stringtable |> collect_tags_for_node(%{key => value}, rest)
      end,
      fn _ -> nil end
    )
  end

  defp collect_tags_for_node(_stringtable, tagmap, [0 | rest]) do
    {[tagmap], rest}
  end

  defp collect_tags_for_node(stringtable, tagmap, [k | [v | rest]]) do
    key = :array.get(k, stringtable)
    value = :array.get(v, stringtable)

    stringtable |> collect_tags_for_node(tagmap |> Map.put(key, value), rest)
  end
end
