defmodule KV.Registry do
  use GenServer

  ## Client API

  @doc "Starts the registry. args: server cb location (cur module), init args, opts"
  def start_link do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  @doc """
  Looks up the bucket pid for name stored in server,
  returns {:ok, pid} if exists, else :error
  synchronous, response required
  """
  def lookup(server, name) do
    GenServer.call(server, {:lookup, name})
  end

  @doc """
  Ensures there is a bucket assoc. to the name in server.
  cast is async, no response sent
  doesn't guarantee receipt by server
  """
  def create(server, name) do
    GenServer.cast(server, {:create, name})
  end

  @doc "stop the registry"
  def stop(server) do
    GenServer.stop(server)
  end

  ## Server callbacks

  @doc """
  receives :ok from start_link, returns {:ok, state}
  """
  def init(:ok) do
    names = %{}
    refs = %{}
    {:ok, {names, refs}}
  end

  @doc """
  args: req, caller process, current server state
  returns {:reply, reply, new_state}
  """
  def handle_call({:lookup, name}, _from, {names, _} = state) do
    {:reply, Map.fetch(names, name), state}
  end


  @doc """
  args: req, current server state
  returns {:noreply, new_state}
  """
  def handle_cast({:create, name}, {names, refs}) do
    if Map.has_key?(names, name) do
      {:noreply, {names, refs}}
    else
      {:ok, pid} = KV.Bucket.start_link
      ref = Process.monitor(pid)
      refs = Map.put(refs, ref, name)
      names = Map.put(names, name, pid)
      {:noreply, {names, refs}}
    end
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    {name, refs} = Map.pop(refs, ref)
    names = Map.delete(names, name)
    {:noreply, {names, refs}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
