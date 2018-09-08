# PBF Parser

## What is it?

Elixir parser and decoder for OpenStreetMap PBF format described in [PBF file specification](https://wiki.openstreetmap.org/wiki/PBF_Format#Encoding_OSM_entities_into_fileblocks). This library provides a collection of functions that one can use to build their own decoder flow of .pbf files, as seen in examples. 

## Installation

Add `pbf_parser` as a dependency in your `mix.exs` file.

```elixir
defp deps do
  [
     # ...
    {:pbf_parser, "~> x.x.x"},
  ]
end
```

Where `x.x.x` equals the version in [`mix.exs`](mix.exs).

Afterwards run `mix deps.get` in your command line to fetch the dependency.

## Usage

#### '''PBFParser.stream/1'''

Opens .pbf file specified by given path and return a '''Stream''' yielding zlib encoded data of consecutive [Blobs](https://wiki.openstreetmap.org/wiki/PBF_Format#File_format). First emitted chunk of data should represent a '''HeaderBlock''', all those coming after should be decoded as '''PrimitiveBlock'''s.

#### '''PBFParser.decompress_header/1'''

Inflates the zlib encoded data and returns a [HeaderBlock](https://wiki.openstreetmap.org/wiki/PBF_Format#Encoding_OSM_entities_into_fileblocks).

#### '''PBFParser.decompress_block/1'''

Inflates the zlib encoded data and returns a [PrimitiveBlock](https://wiki.openstreetmap.org/wiki/PBF_Format#Definition_of_OSMData_fileblock).

#### '''PBFParser.decode_block/1''

Decoded a given '''PrimitiveBlock''' into a list of entities it contains. Each entity is either a '''PBFParser.Data.Node''', a '''PBFParser.Data.Relation''' or '''PBFParser.Data.Way'''. See examples below for details.

## Examples

#### Decoding a block

```elixir
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
```

#### Pipeline Uusing Stream:

```
PBFParser.stream("test.osm.pbf")
|> Stream.drop(1)
|> Stream.map(&PBFParser.decompress_block/1)
|> Stream.map(&PBFParser.decode_block/1)
|> Stream.each(&IO.inspect/1)
|> Stream.run()
```

#### Pipeline using Flow:

```
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
```

## To-Do

 - Add tests