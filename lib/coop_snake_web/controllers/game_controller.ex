defmodule CoopSnakeWeb.GameController do
  use CoopSnakeWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(CoopSnake.PubSub, "tick")
      Phoenix.PubSub.subscribe(CoopSnake.PubSub, "votes")
      CoopSnake.Monitor.monitor(self())
    end

    state = GenServer.call(CoopSnake.Board, :state)

    {
      :ok,
      socket
      |> assign(:board, state.board)
      |> assign(:direction, state.direction)
      |> assign(:vote, nil)
      |> assign(:votes, state.votes),
      temporary_assigns: [board: %{}]
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col min-h-screen w-full items-center justify-center">
      <div class="flex flex-col space-y-5 items-center">
        <h1 class="underline text-3xl uppercase">Hello</h1>
        <div class="flex space-x-4">
          <div id="board" class="grid grid-cols-10" phx-update="append">
            <%= for {tuple, state} <- Enum.to_list(@board) |> Enum.sort_by(fn {{x,y}, _} -> {y, x} end) do %>
              <div
                id={CoopSnake.Board.location_to_id(tuple)}
                class={class_names([
                  "h-10 w-10 outline outline-1",
                  {"bg-red-500", state == :food},
                  {"bg-green-500", state == :snake},
                  {"bg-stone-500", state == :empty}
                ])}
                phx-click="tick"
              >
              </div>
            <% end %>
          </div>
          <div class="flex flex-col space-y-5">
            <span>Current direction: <%= @direction %></span>
            <div class="grid grid-cols-3 w-40 h-40">
              <div></div>
              <button
                type="button"
                class={class_names([
                  "border-[1px] border-black disabled:bg-slate-200",
                  {"bg-red-500", @vote == :up}
                ])}
                phx-click="vote"
                phx-value-direction={:up}
                disabled={!CoopSnake.Board.valid_direction?(@direction, :up)}
              >
              </button>
              <div></div>
              <button
                type="button"
                class={class_names([
                  "border-[1px] border-black disabled:bg-slate-200",
                  {"bg-red-500", @vote == :left}
                ])}
                phx-click="vote"
                phx-value-direction={:left}
                disabled={!CoopSnake.Board.valid_direction?(@direction, :left)}
              >
              </button>
              <div></div>
              <button
                type="button"
                class={class_names([
                  "border-[1px] border-black disabled:bg-slate-200",
                  {"bg-red-500", @vote == :right}
                ])}
                phx-click="vote"
                phx-value-direction={:right}
                disabled={!CoopSnake.Board.valid_direction?(@direction, :right)}
              >
              </button>
              <div></div>
              <button
                type="button"
                class={class_names([
                  "border-[1px] border-black disabled:bg-slate-200",
                  {"bg-red-500", @vote == :down}
                ])}
                phx-click="vote"
                phx-value-direction={:down}
                disabled={!CoopSnake.Board.valid_direction?(@direction, :down)}
              >
              </button>
              <div></div>
            </div>
            <ul>
              <li>Left: <%= @votes.left %></li>
              <li>Right: <%= @votes.right %></li>
              <li>Up: <%= @votes.up %></li>
              <li>Down: <%= @votes.down %></li>
            </ul>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_info({:tick, %{changeset: changeset, direction: direction}}, socket) do
    socket =
      update(socket, :board, &Map.merge(&1, changeset))
      |> update(:direction, fn _ -> direction end)
      |> update(:vote, fn _ -> nil end)
      |> update(:votes, fn _ -> CoopSnake.Board.empty_votes() end)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:votes, votes}, socket) do
    {:noreply, update(socket, :votes, fn _ -> votes end)}
  end

  @impl true
  def handle_event("vote", %{"direction" => direction}, socket) do
    direction = String.to_existing_atom(direction)

    CoopSnake.Board.track_vote(direction, socket.assigns.vote)
    CoopSnake.Monitor.track_vote(self(), direction)

    {:noreply, update(socket, :vote, fn _ -> direction end)}
  end

  @impl true
  def handle_event("tick", _, socket) do
    GenServer.cast(CoopSnake.Board, :tick)

    {:noreply, socket}
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
