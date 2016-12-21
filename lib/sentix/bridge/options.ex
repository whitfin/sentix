defmodule Sentix.Bridge.Options do
  @moduledoc """
  This module handles option parsing for the command line flags Sentix allows
  using against `fswatch`. We separate this into a new module to aid testing and
  keep all logic contained.
  """

  # alias the Bridge
  alias Sentix.Bridge

  @doc """
  Simple accessor for default options.

  This only exists so that we may verify them from test code.
  """
  @spec defaults :: options :: [ binary ]
  def defaults do
    [ "-x", "--event-flag-separator=#{Bridge.divider()}" ]
  end

  @doc """
  Parses out any option flags into command line arguments.

  This function may return arbitrarily nested lists which need flattened before
  being used to execute `fswatch`. Please see `Sentix.start_link/3` for a list
  of available options which can be used.
  """
  @spec parse(options :: Keyword.t) :: options :: [ binary ]
  def parse(options \\ []) when is_list(options) do
    opts = Enum.concat([
      parse_opt(options, :access,      "-a", &parse_truthy_flag/2),
      parse_opt(options, :dir_only,    "-d", &parse_truthy_flag/2),
      parse_opt(options, :excludes,    "-e"),
      parse_opt(options, :filter, "--event", fn(flag, val) ->
        val
        |> List.wrap
        |> Enum.map(&("#{flag}=#{Bridge.convert_name(&1, "binary")}"))
      end),
      parse_opt(options, :includes,    "-i"),
      parse_opt(options, :latency,     "-l", fn(flag, val) ->
        val <= 1.0 and val >= 0.1 && [ flag, inspect(val) ] || []
      end),
      parse_opt(options, :monitor,     "-m"),
      parse_opt(options, :recursive,   "-r", &parse_truthy_flag/2),
      defaults()
    ])
    { :ok, opts }
  end

  @doc """
  Functionally identical to `parse/1`, but extracts the options instead of returning
  as a Tuple.
  """
  @spec parse!(options :: Keyword.t) :: options :: [ binary ]
  def parse!(options \\ []) when is_list(options) do
    options |> parse |> elem(1)
  end

  # Parses out an option from the list of options and transforms it (if existing)
  # using the provided transformation function. This function will return a list
  # of options which should be added to the command execution. The default option
  # transformer is simply to return the flag and value as binaries as they would
  # typically appear in a command line style.
  defp parse_opt(options, opt, flag, opt_transform \\ &([ &1, &2 ])) do
    case Keyword.get(options, opt) do
      nil -> [ ]
      val -> opt_transform.(flag, val)
    end
  end

  # Parses out a flag which designates a true/false switch. If the value is truthy,
  # then we include the flag as an option, otherwise we just provide an empty list.
  defp parse_truthy_flag(flag, val),
  do: val && [ flag ] || [ ]

end
