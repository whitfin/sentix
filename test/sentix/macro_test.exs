defmodule Sentix.MacroTest do
  use ExUnit.Case

  import Sentix.Macro

  test "is_proc/1 determines a process reference" do
    assert(verify(:my_proc))
  end

  test "is_proc/1 determines a process identifier" do
    assert(verify(:erlang.list_to_pid('<0.143.0>')))
  end

  test "is_proc/1 determines an invalid identifier" do
    refute(verify("my_proc"))
  end

  defp verify(value) when is_proc(value), do: true
  defp verify(_value), do: false

end
