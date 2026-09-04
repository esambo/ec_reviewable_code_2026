defmodule Wordl.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      WordlWeb.Telemetry,
      Wordl.Repo,
      {DNSCluster, query: Application.get_env(:wordl, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Wordl.PubSub},
      # Start a worker by calling: Wordl.Worker.start_link(arg)
      # {Wordl.Worker, arg},
      # Start to serve requests, typically the last entry
      WordlWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Wordl.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    WordlWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
