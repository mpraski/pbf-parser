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
    PBFParser.Reader.stream("test.osm.pbf")
    |> Stream.drop(1)
    |> Stream.take(1_000)
    |> Flow.from_enumerable(max_demand: 50)
    |> Flow.partition(max_demand: 5, stages: 5)
    |> Flow.map(&PBFParser.Decoder.decompress_block/1)
    |> Flow.partition(max_demand: 5, stages: 10)
    |> Flow.map(&PBFParser.Decoder.decode_block/1)
    |> Flow.partition(window: Flow.Window.count(20))
    |> Flow.reduce(fn -> [] end, fn batch, total -> [batch | total] end)
    |> Flow.emit(:state)
    |> Flow.partition(max_demand: 5, stages: 1)
    |> Flow.each(fn item -> IO.inspect(length(item)) end)
    |> Flow.run()
  end

  def test_flow_with_metrics do
    Metrics.Collector.start_link([:read, :decompress, :decode])

    specs = [
      {
        {PBFParser.Decompressor, []},
        []
      }
    ]

    stream_metric("test.osm.pbf")
    |> Stream.drop(1)
    |> Stream.take(1_000)
    |> Flow.from_enumerable(max_demand: 50)
    |> Flow.partition(max_demand: 5, stages: 5)
    |> Flow.map(&decompress_block_metric/1)
    |> Flow.partition(max_demand: 5, stages: 10)
    |> Flow.map(&decode_block_metric/1)
    |> Flow.partition(window: Flow.Window.count(20))
    |> Flow.reduce(fn -> [] end, fn batch, total -> [batch | total] end)
    |> Flow.emit(:state)
    |> Flow.partition(max_demand: 5, stages: 1)
    |> Flow.each(fn item -> IO.inspect(length(item)) end)
    |> Flow.run()

    Metrics.Collector.stop()
  end

  defp stream_metric(path) do
    PBFParser.Reader.stream(path) |> Stream.each(fn _ -> Metrics.Collector.incr(:read) end)
  end

  defp decompress_block_metric(data) do
    decomp = Proto.Osm.PrimitiveBlock.decode(:zlib.uncompress(data))
    Metrics.Collector.incr(:decompress)
    decomp
  end

  defp decode_block_metric(block) do
    decoded = PBFParser.Decoder.decode_block(block)
    Metrics.Collector.incr(:decode)
    decoded
  end
end
