defmodule Sentix do
  # we need the `is_proc/1` macro
  import Sentix.Macro

  @moduledoc """
  This module provides the Sentix interface to start a Sentix watcher and then
  subscribe a process afterwards. This module is deliberately small as the aim
  of Sentix is to provide as little behaviour on top of `fswatch` as possible.
  """

  @doc """
  Starts a Sentix watcher and links it to the current process.

  This function requires the name of the watcher to start up, as well as a list
  of paths. In addition you can provide a list of options which will be passed
  through to `fswatch`. Please view the `fswatch` documentation for more information
  as to the behaviour of these flags.

  ## Options

    * `:access` - whether to receive notification of file access events.
    * `:dir_only` - whether to only watch directories.
    * `:excludes` - exclude patterns matching the provided (binary) Regex.
    * `:filter` - only listen for events of this type (can be a list).
    * `:includes` - include patterns matching the provided (binary) Regex.
    * `:latency` - the latency of the monitor events.
    * `:monitor` - specify a monitor to use, rather than the default.
    * `:recursive` - whether or not to recurse subdirectories.

  """
  @spec start_link(name :: atom, paths :: [ binary ], options :: Keyword.t) ::
        { :ok, pid } |
        { :error, reason :: atom | binary }
  def start_link(name, paths, options \\ []) do
    with { :ok, paths } <- enforce_paths(paths) do
      __MODULE__.Watcher.start_link(name, paths, options)
    end
  end

  @doc """
  Shorthand around calling `start_link/3` and then simply removing the link.

  Supports all the same options and works in an identical fashion to `start_link/3`.
  """
  @spec start(name :: atom, paths :: [ binary ], options :: Keyword.t) ::
        { :ok, pid } |
        { :error, reason :: atom | binary }
  def start(name, paths, options \\ []) do
    with { :ok, pid } <- start_link(name, paths, options) do
      :erlang.unlink(pid) && { :ok, pid }
    end
  end

  @doc """
  Subscribes a process to a Sentix watcher.

  If no process name/pid is provided, this will subscribe the calling process. If
  an invalid process identifier is provided, an error will be returned.
  """
  @spec subscribe(name :: atom, sub :: atom | pid) ::
        { :ok, process :: number, subscribers :: [ pid ] } |
        { :error, :noproc }
  def subscribe(name, sub \\ self()) when is_atom(name) and is_proc(sub) do
    GenServer.call(name, { :subscribe, sub })
  end

  # Enforces that all provided paths are binaries. If any are not, then we just
  # return an `:invalid_path` error to inform the user. If all paths are valid,
  # then we expand all provided paths to make sure that everything is normalized
  # further down the execution chain.
  defp enforce_paths(paths) when is_list(paths) do
    if Enum.all?(paths, &is_binary/1) do
      { :ok, Enum.map(paths, &Path.expand/1) }
    else
      { :error, :invalid_path }
    end
  end
  defp enforce_paths(path) when is_binary(path),
    do: enforce_paths([path])
  defp enforce_paths(_path),
    do: { :error, :invalid_path }

end
