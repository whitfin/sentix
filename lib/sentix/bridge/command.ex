defmodule Sentix.Bridge.Command do
  @moduledoc """
  This module provides command construction for executing `fswatch`. This module
  could easily live inside `Sentix.Bridge` but has been separated in order to ease
  testing.
  """

  @doc """
  Generates a flattened list of command segments which can be used to spawn an
  `fswatch` port.

  We flatten everything down to a single level list, and convert all binaries to
  charlists. This is done using a custom recursion in order to aid performance.
  """
  @spec generate(binary :: binary, options :: [ binary ], paths :: [ binary ]) :: { :ok, flags :: [ [ char ] ] }
  def generate(exe, opts, paths) do
    { :ok, Enum.reverse(do_flatten([ exe, opts, paths ], [])) }
  end

  @doc """
  Functionally identical to `generate/1`, but extracts the options instead of returning
  as a Tuple.
  """
  @spec generate!(binary :: binary, options :: [ binary ], paths :: [ binary ]) :: flags :: [ [ char ] ]
  def generate!(exe, opts, paths) do
    exe
    |> generate(opts, paths)
    |> elem(1)
  end

  # Flattens the input parameters by moving through the potential lists of binaries
  # and prepending them to a single level list. Each binary is converted to a
  # charlist as this is the format required when starting ports. It should be noted
  # that this function only ever expects arbitrarily nested lists containing binary
  # values. Anything else will likely cause this function to execute incorrectly.
  defp do_flatten([ ], flattened),
    do: flattened
  defp do_flatten([ h | t ], flattened) when is_list(h),
    do: do_flatten(t, do_flatten(h, []) ++ flattened)
  defp do_flatten([ h | t ], flattened),
    do: do_flatten(t, [ to_char_list(h) | flattened ])

end
