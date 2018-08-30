defmodule PBFParser.Decompressor do
  use GenStage

  def start_link(opts \\ []) do
    GenStage.start_link(__MODULE__, opts)
  end

  def init(_) do
    {:producer_consumer, :zlib.open()}
  end

  def handle_events(events, _from, z) do
    :zlib.inflateInit(z)

    decompressed =
      events
      |> Enum.map(fn event ->
        Proto.Osm.PrimitiveBlock.decode(:zlib.inflate(z, event) |> :erlang.iolist_to_binary())
      end)

    :zlib.inflateEnd(z)

    {:noreply, decompressed, z}
  end

  def handle_cancel(cancellation_reason, _from, z) do
    :zlib.close(z)

    {:stop, cancellation_reason, nil}
  end
end
