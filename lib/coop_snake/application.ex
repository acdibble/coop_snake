defmodule CoopSnake.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      CoopSnakeWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: CoopSnake.PubSub},
      # Start the Endpoint (http/https)
      CoopSnakeWeb.Endpoint,
      # Start a worker by calling: CoopSnake.Worker.start_link(arg)
      # {CoopSnake.Worker, arg}
      CoopSnake.Board,
      CoopSnake.Monitor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CoopSnake.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CoopSnakeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
