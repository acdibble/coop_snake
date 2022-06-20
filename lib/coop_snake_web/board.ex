defmodule CoopSnake.Board do
  use Agent

  def start_link(_arg) do
    board_size = 9

    Agent.start_link(
      fn ->
        for y <- 0..board_size, x <- 0..board_size do
          {"cell-#{x}_#{y}", :off}
        end
        |> Map.new()
      end,
      name: __MODULE__
    )
  end

  def value do
    Agent.get(__MODULE__, & &1)
  end

  def toggle_cell(id) do
    old_value =
      Agent.get_and_update(__MODULE__, fn state ->
        Map.get_and_update(state, id, &{&1, toggle(&1)})
      end)

    Phoenix.PubSub.broadcast(
      CoopSnake.PubSub,
      "toggled",
      {:toggled, {id, toggle(old_value)}}
    )
  end

  defp toggle(:on), do: :off
  defp toggle(:off), do: :on
end
