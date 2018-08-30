defmodule Metrics.Collector do
  use GenServer

  @timeres :millisecond

  def start_link(scopes \\ []) do
    GenServer.start_link(__MODULE__, scopes, name: __MODULE__)
  end

  def stop() do
    GenServer.stop(__MODULE__)
  end

  def incr(scope, amount \\ 1) do
    GenServer.cast(__MODULE__, {:incr, scope, amount})
  end

  def init(scopes) do
    files =
      scopes
      |> Enum.map(fn scope ->
        {scope, File.open!(Path.expand("../../metrics/progress-#{scope}.log", __DIR__), [:write])}
      end)

    counts = scopes |> Enum.map(fn scope -> {scope, 0} end)

    time = :os.system_time(@timeres)

    # write first data point for every scope with current time and value 0
    # this helps to keep the graph starting nicely at (0,0) point
    files |> Enum.each(fn {_, file} -> write(file, time, 0) end)

    {:ok, {time, files, counts}}
  end

  def handle_cast({:incr, scope, amount}, {time, files, counts}) do
    # update counter
    {value, counts} = Keyword.get_and_update!(counts, scope, &{&1 + amount, &1 + amount})

    # write new data point
    write(files[scope], time, value)

    {:noreply, {time, files, counts}}
  end

  defp write(file, time, amount) do
    time = :os.system_time(@timeres) - time
    IO.write(file, "#{time}\t#{amount}\n")
  end
end
