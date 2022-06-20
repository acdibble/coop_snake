defmodule CoopSnake.Store do
  use Agent

  def start_link(_arg) do
    Agent.start_link(fn -> %{user_count: 0, click_count: 0} end, name: __MODULE__)
  end

  def value do
    Agent.get(__MODULE__, & &1)
  end

  def increment(:user_count), do: update_state(:user_count, :increment)
  def increment(:click_count), do: update_state(:click_count, :increment)

  def decrement(:user_count), do: update_state(:user_count, :decrement)
  def decrement(:click_count), do: update_state(:click_count, :decrement)

  defp update_state(key, type) do
    fun =
      case type do
        :increment -> &Kernel.+/2
        :decrement -> &Kernel.-/2
      end

    Phoenix.PubSub.broadcast(
      CoopSnake.PubSub,
      to_string(key),
      {key,
       Agent.get_and_update(__MODULE__, fn state ->
         {old_value, new_state} = Map.get_and_update(state, key, &{&1, fun.(&1, 1)})
         {fun.(old_value, 1), new_state}
       end)}
    )
  end
end
