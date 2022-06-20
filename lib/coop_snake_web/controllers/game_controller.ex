defmodule CoopSnakeWeb.GameController do
  use CoopSnakeWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(CoopSnake.PubSub, "click_count")
      Phoenix.PubSub.subscribe(CoopSnake.PubSub, "user_count")
      CoopSnake.Monitor.monitor(self())
    end

    %{click_count: click_count, user_count: user_count} = CoopSnake.Store.value()

    {
      :ok,
      socket
      |> assign(:click_count, click_count)
      |> assign(:user_count, user_count)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col space-x-2">
      <h1 class="underline text-3xl uppercase">Hello</h1>
      <div>Count: <%= @click_count %></div>
      <div class="flex space-x-2">
        <button
          type="button"
          class="bg-green-500 h-5 w-5 flex items-center justify-center rounded"
          phx-click="inc"
        >
          <span>+</span>
        </button>
        <button
          type="button"
          class="bg-red-500 h-5 w-5 flex items-center justify-center rounded"
          phx-click="dec"
        >
          <span>-</span>
        </button>
      </div>
      <span>Users: <%= @user_count %></span>
    </div>
    """
  end

  @impl true
  def handle_event("inc", _params, socket) do
    CoopSnake.Store.increment(:click_count)

    {:noreply, socket}
  end

  @impl true
  def handle_event("dec", _params, socket) do
    CoopSnake.Store.decrement(:click_count)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:click_count, new_count}, socket) do
    {:noreply, update(socket, :click_count, fn _ -> new_count end)}
  end

  @impl true
  def handle_info({:user_count, new_count}, socket) do
    {:noreply, update(socket, :user_count, fn _ -> new_count end)}
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
