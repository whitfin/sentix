defmodule Sentix.Watcher do
  @moduledoc """
  """

  # add GenServer bindings
  use GenServer

  # we need a Logger
  require Logger

  # add some aliases
  alias Sentix.Bridge
  alias Sentix.Cache

  @doc """
  Starts a Sentix watcher using the provided name, paths and options.

  If the `fswatch` binary cannot be located, an error will be returned.
  """
  @spec start_link(name :: atom, paths :: [ binary ], options :: Keyword.t) ::
        { :ok, pid } |
        { :error, reason :: atom | binary }
  def start_link(name, paths, options) do
    with { :ok, _exe } <- Cache.find_binary('fswatch') do
      GenServer.start_link(__MODULE__, { name, paths, options }, [ name: name ])
    end
  end

  @doc """
  Main initialization for a watcher, opening a bridge to the `fswatch` port.
  """
  @spec init({ name :: atom, paths :: [ binary ], options :: Keyword.t }) ::
        { :ok, { name :: atom, process :: number, subscribers :: [ pid ]} }
  def init({ name, paths, options }) do
    # open up a bridge to talk to the fswatch port
    { :ok, _pid, proc } = Bridge.open(paths, options)
    # retrieve any previous subscribers
    { :ok, { name, proc, Cache.get_subscribers(name) } }
  end

  @doc false
  # Handles the addition of a subscriber against this Sentix watcher. We first
  # validate the subscriber reference passed in and prepend it to the list of
  # subscribers. We then persist the new subscriber into the cache. A subscriber
  # can be either of a pid or a registered atom name representing a process.
  def handle_call({ :subscribe, subscriber }, _ctx, { name, proc, subscribers } = state) do
    case do_subscribe(subscriber) do
      { :error, :noproc } = res ->
        # return error as is
        { :reply, res, state }
      { :ok, sub } ->
        # add the new subscriber to the cached set
        new_set = Cache.add_subscriber(name, subscribers, sub)
        # return the process id and the list of subscribers
        { :reply, { :ok, proc, new_set }, { name, proc, new_set } }
    end
  end

  @doc false
  # Listens on stdout coming over the bridge. This will receive each line of
  # output coming from `fswatch`, and will then convert it to a message syntax
  # which is easier to consume. Once done, we then forward the message to all
  # known subscribers (that are still alive). If a subscriber is not alive, it
  # is at this point in time that we will trim it from the subscribers list.
  def handle_info({ :stdout, proc, data }, { name, proc, subscribers }) do
    alive_subs = Enum.filter(subscribers, &alive?/1)
    event_list = create_events(proc, data)

    for event <- event_list, sub <- alive_subs do
      send(sub, event)
    end

    { :noreply, { name, proc, Cache.set_subscribers(name, alive_subs) } }
  end

  @doc false
  # Listens on stderr coming over the bridge. We log this out as an error and
  # continue. If this is an error which halts the port, then we'll receive a
  # DOWN message which will terminate this server, so we don't need to address
  # that at this point, simply log the error.
  def handle_info({ :stderr, _proc, data }, state) do
    data
    |> String.replace_trailing("\n", "")
    |> Logger.error
    { :noreply, state }
  end

  @doc false
  # Catches the exit of the fswatch port (which should never happen), but in the
  # case that it does, we kill the watcher. This means that if the watcher is in
  # a supervision tree, it will be restarted and likely reopen a new port.
  def handle_info({ :DOWN, _ref, :process, _from, _reason }, _state) do
    exit(:port_terminated)
  end

  @doc false
  # Catch-all for messages we don't recognise.
  def handle_info(_msg, state) do
    { :noreply, state }
  end

  # Checks to see whether a process is alive or not. We allow either a pid or an
  # atom ref so we need to check both. To check the atom ref, we just locate the
  # pointer of the ref before passing it back to `alive?/2` to treat it as a pid.
  defp alive?(ref) when is_pid(ref),
    do: Process.alive?(ref)
  defp alive?(ref) when is_atom(ref) do
    case Process.whereis(ref) do
      nil -> false
      val -> alive?(val)
    end
  end

  # Creates an event to broadcast to all subscribers. We take the input binary
  # data and resolve the filename and events emitted. The event names are converted
  # to a more Elixir-friendly format (atoms), before being used to create a Tuple
  # consisting of the process id, a type flag, and a Tuple of the filename and
  # emitted event list. The structure is inspied by that of the `fs` library in
  # order to make migration from that project easier for anyone who wishes to.
  defp create_events(proc, data) do
    messages =
      data
      |> String.replace_trailing("\n", "")
      |> String.split("\n")

    Enum.map(messages, fn(message) ->
      { tchunk, [ echunk ] } =
        message
        |> String.split(" ")
        |> Enum.split(-1)

      target = Enum.join(tchunk, " ")
      events =
        echunk
        |> String.split(Bridge.divider())
        |> Enum.map(&Bridge.convert_name/1)

      { proc, { :fswatch, :file_event }, { target, events } }
    end)
  end

  # Handles the subscription of a new subscriber to the watcher. We only allow
  # for atom references and process identifiers, and so we need to validate them
  # at least as far as this. If the value is neither, then we return an error to
  # forward back to the developer.
  defp do_subscribe(subscriber) when is_pid(subscriber) do
    { :ok, subscriber }
  end
  defp do_subscribe(subscriber) when is_atom(subscriber) do
    case Process.whereis(subscriber) do
      nil -> { :error, :noproc }
      _na -> { :ok, subscriber }
    end
  end
  defp do_subscribe(_subscriber) do
    { :error, :noproc }
  end

end
