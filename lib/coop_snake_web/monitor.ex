defmodule CoopSnake.Monitor do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def monitor(pid) do
    GenServer.call(__MODULE__, {:monitor, pid})
  end

  def track_vote(pid, vote) do
    GenServer.cast(__MODULE__, {:vote, pid, vote})
  end

  def clear() do
    GenServer.cast(__MODULE__, :clear)
  end

  @impl true
  def init(map) do
    {:ok, map}
  end

  @impl true
  def handle_call({:monitor, pid}, _from, map) do
    Process.monitor(pid)
    {:reply, :ok, map}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, map) do
    {vote, new_state} = Map.pop(map, pid)

    CoopSnake.Board.unvote(vote)

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:vote, pid, vote}, map) do
    {:noreply, Map.put(map, pid, vote)}
  end

  @impl true
  def handle_cast(:clear, _map) do
    {:noreply, %{}}
  end
end
