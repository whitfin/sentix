defmodule Sentix.Bridge do
  @moduledoc """
  This module provides the bridge between Sentix and `fswatch`, via an Erlang
  port. This is where any translation will be done in order to handle the types
  of communication between the port and the program.
  """

  # add internal aliases
  alias __MODULE__.{
    Command, Options
  }

  @doc """
  Opens a bridged port to `fswatch`, using the provided paths and options.

  We listen on `stdout` from `fswatch` so that we may forward the output to any
  subscribers. In addition, we monitor the port to ensure that any host server
  will crash if the port does, allowing Supervision trees to restart the ports.

  The options available are described in `Sentix.start_link/3`, so please view
  documentation there for further information.
  """
  @spec open(paths :: [ binary ], options :: Keyword.t) ::
        { :ok, pid, process :: number } |
        { :error, reason :: atom } |
        { :error, reason :: binary }
  def open(paths, options \\ []) when is_list(paths) and is_list(options) do
    with { :ok,  exe } <- Command.locate_fswatch(),
         { :ok, opts } <- Options.parse(options),
         { :ok,  cmd } <- Command.generate(exe, opts, paths),
     do: :exec.run(cmd, [ :stdout, :stderr, :monitor ])
  end

  @doc """
  Converts an event name between the Sentix representation and the `fswatch`
  representation.

  The conversion technique used is determined by the type of the passed in event,
  as atoms are converted to `fswatch` style, and binaries are converted to Sentix
  style.
  """
  @spec convert_name(event :: atom | binary) :: event :: binary | atom
  def convert_name(event) when is_binary(event) do
    event
    |> Macro.underscore
    |> String.to_atom
  end
  def convert_name(event) when is_atom(event) do
    event
    |> Kernel.to_string
    |> Macro.camelize
  end

  @doc """
  Similar to `convert_name/1` but with the ability to enforce a type.

  This means that we can safely no-op if we already have the style of name we want.
  """
  @spec convert_name(event :: atom | binary, style :: binary) :: event :: binary | atom
  def convert_name(event, "atom") when is_atom(event),
    do: event
  def convert_name(event, "binary") when is_binary(event),
    do: event
  def convert_name(event, _style),
    do: convert_name(event)

end
