defmodule Sentix.MacroTest do
  use ExUnit.Case

  # we need to import macros
  import Sentix.Macro

  # This test just ensures that the is_proc/1 macro correctly determines whether
  # we have provided a process name or a process identifier. We define a function
  # in this module using the macro as a guard in order to correctly replicate the
  # conditions in which it's used. We also negatively test to make sure that we
  # don't provide false positives, and return false as expected.
  test "is_proc/1 determines a process reference" do
    # verify various references
    result1 = verify(:my_proc)
    result2 = verify(:erlang.list_to_pid('<0.143.0>'))
    result3 = verify("my_proc")

    # the first two should be valid
    assert(result1)
    assert(result2)

    # the third is invalid
    refute(result3)
  end

  # A small util function internally to use the is_proc guard and convert it into
  # a boolean value which is easy to consume from within tests.
  defp verify(value) when is_proc(value), do: true
  defp verify(_value), do: false

end
