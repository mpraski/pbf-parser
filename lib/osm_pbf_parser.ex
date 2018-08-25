defmodule PBFParser do
  @moduledoc """
  Documentation for PBFParser.
  """

  @doc """
  ## Examples

      iex> PBFParser.parse("test.osm.pbf") |> Enum.take(4) |> Enum.each(&IO.inspect(&1))

  """
  def parse(path) do
    start_fn = fn ->
      {:ok, file} = :file.open(path, [:raw, :binary, :read, {:read_ahead, 65536}])
      file
    end

    next_fn = fn file ->
      case :file.read(file, 4) do
        :eof ->
          {:halt, file}

        {:ok, header_size_bytes} ->
          header_size = header_size_bytes |> :binary.decode_unsigned()

          {:ok, header_bytes} = :file.read(file, header_size)
          header = PBFParser.File.BlobHeader.decode(header_bytes)

          {:ok, blob_bytes} = :file.read(file, header.datasize)
          blob = PBFParser.File.Blob.decode(blob_bytes)

          zlib_uncompressed = :zlib.uncompress(blob.zlib_data)

          data_block =
            case header.type do
              "OSMHeader" ->
                PBFParser.Osm.HeaderBlock.decode(zlib_uncompressed)

              "OSMData" ->
                PBFParser.Osm.PrimitiveBlock.decode(zlib_uncompressed)
            end

          {[data_block], file}
      end
    end

    after_fn = fn file -> :file.close(file) end

    Stream.resource(start_fn, next_fn, after_fn)
  end
end
