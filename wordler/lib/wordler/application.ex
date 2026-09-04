defmodule Wordler.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      WordlerWeb.Telemetry,
      Wordler.Repo,
      {DNSCluster, query: Application.get_env(:wordler, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Wordler.PubSub},
      # Start a worker by calling: Wordler.Worker.start_link(arg)
      # {Wordler.Worker, arg},
      # Start to serve requests, typically the last entry
      WordlerWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Wordler.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    WordlerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
