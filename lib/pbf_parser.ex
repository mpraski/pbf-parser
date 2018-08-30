defmodule PBFParser do
  def test do
    PBFParser.Reader.stream("test.osm.pbf")
    |> Stream.drop(1)
    |> Stream.map(&PBFParser.Decoder.decompress_block/1)
    |> Stream.map(&PBFParser.Decoder.decode_block/1)
    |> Stream.each(&IO.inspect/1)
    |> Stream.run()
  end

  def test_flow do
    Metrics.Collector.start_link([:read, :decompress, :decode])

    PBFParser.Reader.stream("test.osm.pbf")
    |> Stream.drop(1)
    |> Flow.from_enumerable(max_demand: 100)
    |> Flow.partition(max_demand: 5, stages: 6)
    |> Flow.map(&PBFParser.Decoder.decompress_block/1)
    |> Flow.partition(max_demand: 5, stages: 12)
    |> Flow.map(&PBFParser.Decoder.decode_block/1)
    |> Flow.partition(window: Flow.Window.count(20))
    |> Flow.reduce(fn -> [] end, fn batch, total -> [batch | total] end)
    |> Flow.emit(:state)
    |> Flow.partition(max_demand: 20, stages: 2)
    |> Flow.each(fn item -> IO.inspect(length(item)) end)
    |> Flow.run()

    Metrics.Collector.stop()
  end

  def test_flow_with_metrics do
    Metrics.Collector.start_link([:read, :decompress, :decode, :collect])

    specs = [
      {
        {PBFParser.Decompressor, []},
        []
      }
    ]

    PBFParser.Reader.stream("test.osm.pbf")
    |> Stream.drop(1)
    |> Stream.take(1_000)
    |> Flow.from_enumerable(max_demand: 100)
    # |> Flow.through_specs(specs, max_demand: 5, stages: 6)
    |> Flow.partition(max_demand: 5, stages: 6)
    |> Flow.map(&PBFParser.Decoder.decompress_block/1)
    |> Flow.partition(max_demand: 5, stages: 12)
    |> Flow.map(&PBFParser.Decoder.decode_block/1)
    |> Flow.partition(window: Flow.Window.count(20))
    |> Flow.reduce(fn -> [] end, fn batch, total ->
      Metrics.Collector.incr(:collect)
      [batch | total]
    end)
    |> Flow.emit(:state)
    |> Flow.partition(max_demand: 20, stages: 2)
    |> Flow.each(fn item -> IO.inspect(length(item)) end)
    |> Flow.run()

    Metrics.Collector.stop()
  end
end
