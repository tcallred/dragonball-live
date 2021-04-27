defmodule Dragonball.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      DragonballWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Dragonball.PubSub},
      # Start the Endpoint (http/https)
      DragonballWeb.Endpoint
      # Start a worker by calling: Dragonball.Worker.start_link(arg)
      # {Dragonball.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Dragonball.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    DragonballWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
