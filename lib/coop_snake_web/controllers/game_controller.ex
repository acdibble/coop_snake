defmodule CoopSnakeWeb.GameController do
  use CoopSnakeWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(CoopSnake.PubSub, "tick")
      # CoopSnake.Monitor.monitor(self())
    end

    {
      :ok,
      assign(socket, :board, CoopSnake.Board.value() |> elem(0)),
      temporary_assigns: [board: %{}]
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col min-h-screen w-full items-center justify-center">
      <div class="flex flex-col space-y-5 items-center">
        <h1 class="underline text-3xl uppercase">Hello</h1>
        <div id="board" class="grid grid-cols-10" phx-update="append">
          <%= for {id, state} <- Enum.to_list(@board) |> Enum.sort() do %>
            <div
              id={id}
              class={class_names([
                "h-10 w-10 outline outline-1",
                {"bg-red-500", state == :food},
                {"bg-green-500", state == :snake},
                {"bg-slate-500", state == :empty}
              ])}
              phx-click="toggle"
              phx-value-id={id}
            >
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("toggle", _, socket) do
    CoopSnake.Board.tick()

    {:noreply, socket}
  end

  @impl true
  def handle_info({:tick, changed_values}, socket) do
    {
      :noreply,
      update(socket, :board, &Map.merge(&1, changed_values))
    }
  end

  def class_names(list) do
    Enum.map(list, fn el ->
      case el do
        el when is_binary(el) -> el
        {_, false} -> nil
        {class, true} -> class
      end
    end)
    |> Enum.filter(&is_binary/1)
    |> Enum.join(" ")
  end
end
