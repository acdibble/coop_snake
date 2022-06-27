defmodule CoopSnake.Board do
  use Agent

  @board_size 9

  @directions [:up, :right, :down, :left]

  def start_link(_arg) do
    Agent.start_link(&starting_state/0, name: __MODULE__)
  end

  defp starting_state do
    board =
      for y <- 0..@board_size, x <- 0..@board_size do
        {"cell-#{x}-#{y}", :empty}
      end
      |> Map.new()

    {board, :queue.in(random_location(), :queue.new()), random_direction()}
  end

  defp update(state) do
    Agent.update(__MODULE__, fn _ -> state end)
  end

  def value do
    Agent.get(__MODULE__, & &1)
  end

  def tick() do
    value()
    |> paint()
    |> update()
  end

  defp random_location() do
    {Enum.random(0..@board_size), Enum.random(0..@board_size)}
  end

  defp random_direction() do
    Enum.random(@directions)
  end

  defp paint({board, snake, direction}) do
    {x, y} = :queue.head(snake)

    {{:value, {tail_x, tail_y}}, snake} = :queue.out(snake)

    {x, y} =
      case direction do
        :up -> {x, y - 1}
        :right -> {x + 1, y}
        :down -> {x, y + 1}
        :left -> {x - 1, y}
      end

    snake = :queue.in({x, y}, snake)

    changed_values =
      Map.new()
      |> Map.put("cell-#{tail_x}-#{tail_y}", :empty)
      |> Map.put("cell-#{x}-#{y}", :snake)

    Phoenix.PubSub.broadcast(
      CoopSnake.PubSub,
      "tick",
      {:tick, changed_values}
    )

    {
      board |> Map.merge(changed_values),
      snake,
      direction
    }
  end
end
