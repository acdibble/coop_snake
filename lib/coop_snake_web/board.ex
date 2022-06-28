defmodule CoopSnake.Board do
  use GenServer

  defstruct [:board, :food, :snake, :direction, :votes]

  @board_size 9

  @directions [:up, :right, :down, :left]

  @tick_length 5000

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  defp now() do
    DateTime.utc_now() |> DateTime.to_unix(:millisecond)
  end

  @impl true
  def init(_) do
    loop(now())

    {:ok, new()}
  end

  defp loop(started_at) do
    Process.send_after(self(), :tick, @tick_length - (now() - started_at))
  end

  @impl true
  def handle_info(:tick, state) do
    started_at = now()

    state = tick(state)

    loop(started_at)

    {:noreply, state}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:vote, new_vote, old_vote}, state) do
    votes =
      case old_vote do
        nil -> state.votes
        _ -> Map.update!(state.votes, old_vote, &(&1 - 1))
      end
      |> Map.update!(new_vote, &(&1 + 1))

    Phoenix.PubSub.broadcast(CoopSnake.PubSub, "votes", {:votes, votes})

    {:noreply, %CoopSnake.Board{state | votes: votes}}
  end

  defp new() do
    snake_head = random_location()
    food = random_location()

    board =
      for(y <- 0..@board_size, x <- 0..@board_size, do: {{x, y}, :empty})
      |> Map.new()
      |> Map.put(snake_head, :snake)
      |> Map.put(food, :food)

    %CoopSnake.Board{
      board: board,
      snake: :queue.in(snake_head, :queue.new()),
      food: food,
      direction: random_direction(),
      votes: empty_votes()
    }
  end

  def tick(state) do
    state
    |> decide_election()
    |> move_snake()
    |> move_food()
    |> notify()
  end

  defp random_location() do
    {Enum.random(0..@board_size), Enum.random(0..@board_size)}
  end

  defp random_direction() do
    Enum.random(@directions)
  end

  def location_to_id(location) do
    "cell-#{elem(location, 0)}-#{elem(location, 1)}"
  end

  def empty_votes(), do: %{left: 0, right: 0, up: 0, down: 0}

  defp decide_winner({_, count_a} = a, {_, count_b} = b, mode) do
    cond do
      count_a == count_b && mode == :random -> Enum.random([a, b])
      count_a == count_b && mode == :last -> b
      count_a > count_b -> a
      count_a < count_b -> b
    end
  end

  defp decide_election(%CoopSnake.Board{direction: direction, votes: votes} = state) do
    [a, b] =
      Enum.filter(votes, fn {dir, _} -> valid_direction?(direction, dir) && dir != direction end)
      |> Enum.to_list()

    {winner, _} =
      decide_winner(a, b, :random)
      |> decide_winner({direction, votes[direction]}, :last)

    %CoopSnake.Board{state | votes: empty_votes(), direction: winner}
  end

  defp move_snake(%CoopSnake.Board{snake: snake, direction: direction} = state) do
    {x, y} = :queue.head(snake)

    new_head =
      case direction do
        :up -> {x, y - 1}
        :right -> {x + 1, y}
        :down -> {x, y + 1}
        :left -> {x - 1, y}
      end

    case in_bounds?(new_head) do
      true -> {:ok, {new_head, state}}
      _ -> {:error, {:out_of_bounds, state}}
    end
  end

  defp move_food({:ok, {new_head, %CoopSnake.Board{food: food} = state}}) do
    {{:value, tail}, snake} = :queue.out(state.snake)
    snake = :queue.in(new_head, snake)

    changeset =
      Map.new()
      |> Map.put(tail, :empty)
      |> Map.put(new_head, :snake)

    board = Map.merge(state.board, changeset)

    {changeset, board} =
      case new_head do
        ^food ->
          new_food =
            Map.filter(board, fn {_, value} -> value == :empty end)
            |> Enum.random()
            # TODO: handle victory
            |> elem(0)

          changeset = Map.put(changeset, new_food, :food)
          board = Map.put(board, new_food, :food)
          {changeset, board}

        _ ->
          {changeset, board}
      end

    {:ok, changeset, %CoopSnake.Board{state | board: board, snake: snake}}
  end

  defp move_food({:error, _} = failure), do: failure

  defp notify({:ok, changeset, state}) do
    Phoenix.PubSub.broadcast(
      CoopSnake.PubSub,
      "tick",
      {:tick, %{changeset: changeset, direction: state.direction}}
    )

    state
  end

  defp notify({:error, {_message, state}}) do
    next = new()

    changeset =
      Enum.filter(state.board, fn {_key, value} -> value != :empty end)
      |> Enum.map(fn {key, _value} -> {key, :empty} end)
      |> Map.new()
      |> Map.put(next.food, :food)
      |> Map.put(:queue.head(next.snake), :snake)

    notify({:ok, changeset, next})
  end

  defp in_bounds?(location) do
    {x, y} = location
    x >= 0 && x <= @board_size && y >= 0 && y <= @board_size
  end

  def valid_direction?(:left, :left), do: true
  def valid_direction?(:left, :right), do: false
  def valid_direction?(:left, :up), do: true
  def valid_direction?(:left, :down), do: true
  def valid_direction?(:right, :left), do: false
  def valid_direction?(:right, :right), do: true
  def valid_direction?(:right, :up), do: true
  def valid_direction?(:right, :down), do: true
  def valid_direction?(:down, :left), do: true
  def valid_direction?(:down, :right), do: true
  def valid_direction?(:down, :up), do: false
  def valid_direction?(:down, :down), do: true
  def valid_direction?(:up, :left), do: true
  def valid_direction?(:up, :right), do: true
  def valid_direction?(:up, :up), do: true
  def valid_direction?(:up, :down), do: false
end
