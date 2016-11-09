defmodule KV.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      worker(KV.Registry, [KV.Registry]),
      supervisor(KV.Bucket.Supervisor, [])
    ]

    # only kill/restart child process that were started after the crashed child
    # if registry worker crashes, restart it and bucket supervisor
    # keep registry worker running if bucket supervisor crashes
    supervise(children, strategy: :rest_for_one)
  end
end
