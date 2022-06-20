defmodule CoopSnake.Monitor do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def monitor(pid) do
    GenServer.call(__MODULE__, {:monitor, pid})
  end

  @impl true
  def init(map) do
    {:ok, map}
  end

  @impl true
  def handle_call({:monitor, pid}, _from, map) do
    Process.monitor(pid)
    CoopSnake.Store.increment(:user_count)
    {:reply, :ok, map}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, map) do
    # {driver_id, map} = Map.pop(map, socket_pid)
    IO.inspect(pid, label: "disconnect")
    CoopSnake.Store.decrement(:user_count)
    {:noreply, map}
  end
end
