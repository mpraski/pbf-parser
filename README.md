# PBFParser

Elixir parser for OpenStreetMap PBF format.

## Usage

PBFParser.parse(path) returns a stream of entities (HeaderBlock or PrimiveBlock) described in [PBF file specification](https://wiki.openstreetmap.org/wiki/PBF_Format#Encoding_OSM_entities_into_fileblocks).

## To-Do

Extract information from basic blocks and present it in clearer manner.