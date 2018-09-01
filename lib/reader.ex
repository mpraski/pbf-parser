defmodule PBFParser.Reader do
  def stream(path) do
    Stream.resource(fn -> open_file(path) end, &read_next/1, &close_file/1)
  end

  defp open_file(path) do
    {:ok, file} = :file.open(path, [:raw, :binary, :read, {:read_ahead, 100_000}])
    file
  end

  defp close_file(file) do
    :file.close(file)
  end

  defp read_next(file) do
    case :file.read(file, 4) do
      :eof ->
        {:halt, file}

      {:ok, header_size_bytes} ->
        header_size = header_size_bytes |> :binary.decode_unsigned()

        {:ok, header_bytes} = :file.read(file, header_size)
        %{datasize: datasize} = Proto.File.BlobHeader.decode(header_bytes)

        {:ok, blob_bytes} = :file.read(file, datasize)
        %{zlib_data: zlib_data} = Proto.File.Blob.decode(blob_bytes)

        {[zlib_data], file}
    end
  end
end
