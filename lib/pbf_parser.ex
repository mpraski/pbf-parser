defmodule PBFParser do
  @moduledoc """
  Elixir parser and decoder for OpenStreetMap PBF format described in [PBF file specification](https://wiki.openstreetmap.org/wiki/PBF_Format#Encoding_OSM_entities_into_fileblocks). This library provides a collection of functions that one can use to build their own decoder flow of .pbf files, as seen in examples.

  ## Examples

  #### With Stream

      PBFParser.stream("test.osm.pbf")
        |> Stream.drop(1)
        |> Stream.map(&PBFParser.decompress_block/1)
        |> Stream.map(&PBFParser.decode_block/1)
        |> Stream.each(&IO.inspect/1)
        |> Stream.run()

  #### With Flow

      PBFParser.stream("test.osm.pbf")
        |> Stream.drop(1)
        |> Stream.take(1_000)
        |> Flow.from_enumerable(max_demand: 50)
        |> Flow.partition(max_demand: 5, stages: 5)
        |> Flow.map(&PBFParser.decompress_block/1)
        |> Flow.partition(max_demand: 5, stages: 10)
        |> Flow.map(&PBFParser.decode_block/1)
        |> Flow.partition(window: Flow.Window.count(20))
        |> Flow.reduce(fn -> [] end, fn batch, total -> [batch | total] end)
        |> Flow.emit(:state)
        |> Flow.partition(max_demand: 5, stages: 1)
        |> Flow.each(fn item -> IO.inspect(length(item)) end)
        |> Flow.run()
  """

  alias PBFParser.Proto.OsmFormat.{
    PrimitiveBlock,
    HeaderBlock
  }

  @doc """
  Opens .pbf file specified by given path and return a `Stream` yielding zlib encoded data of consecutive Blobs.
  First emitted chunk of data should represent a `HeaderBlock`,
  all those coming after should be decoded as `PrimitiveBlock`s.
  """
  @spec stream(String.t()) :: Enumerable.t()
  defdelegate stream(path), to: PBFParser.Reader

  @doc """
  Decompresses zlib encoded header data (as obtained from `PBFParser.stream/1`).

  Returns `HeaderBlock`, a struct generated directly from PBF protobuf specification.
  """
  @spec decompress_header(iodata()) :: HeaderBlock.t()
  defdelegate decompress_header(data), to: PBFParser.Decoder

  @doc """
  Decompresses zlib encoded block data (as obtained from `PBFParser.stream/1`).

  Returns `PrimitiveBlock`, a struct generated directly from PBF protobuf specification.
  """
  @spec decompress_block(iodata()) :: PrimitiveBlock.t()
  defdelegate decompress_block(data), to: PBFParser.Decoder

  @doc """
  Decodes the raw `PrimitiveBlock` (as obtained from `PBFParser.decompress_block/1`) into a more usable format.
  Each block usually contains around 8000 densely packed node entities and a number of relation and way
  entities. Those are extracted along with accompanying metadata.

  Returns a list containing `PBFParser.Data.Node`, `PBFParser.Data.Relation` and `PBFParser.Data.Way` structs.

  ## Example
      iex(1)> PBFParser.decode_decode_block(...)
      [
          ...
          %PBFParser.Data.Node{
          id: 219219898,
          info: %PBFParser.Data.Info{
            changeset: 0,
            timestamp: #DateTime<2008-01-11 23:29:41.000Z>,
            uid: 0,
            user: "",
            version: 1,
            visible: nil
          },
          latitude: 14.860650000000001,
          longitude: -83.43016,
          tags: %{"created_by" => "JOSM"}
        },
        ...
      ]
  """
  @spec decode_block(PrimitiveBlock.t()) :: [Data.Node.t() | Data.Relation.t() | Data.Way.t()]
  defdelegate decode_block(block), to: PBFParser.Decoder
end
