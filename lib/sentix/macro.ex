defmodule Sentix.Macro do
  @moduledoc """
  This module contains any macros which need to be used inside Sentix. Currently
  very small and only contains guard macros.
  """

  @doc """
  Determines if a value is a process identifier, either a pid or an atom.
  """
  defmacro is_proc(proc) do
    quote do
      is_pid(unquote(proc)) or is_atom(unquote(proc))
    end
  end

end
