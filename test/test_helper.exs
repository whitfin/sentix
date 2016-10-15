# internal module
defmodule TestHelper do
  @moduledoc false
  # This module exists because we need a contextual helper in order to be able
  # to execute the ExUnit callbacks. Therefore this module is just a wrapper of
  # these callbacks.

  # test context
  require ExUnit.Case

  # letter constant
  @letters Enum.to_list(?a..?z)

  @doc false
  # Creates a name for a Sentix watcher and schedules it to be stopped after this
  # run of tests.
  def create_name do
    name =
      1..16
      |> Enum.map(fn(_) -> Enum.random(@letters) end)
      |> List.to_string
      |> String.to_atom

    ExUnit.Callbacks.on_exit("kill #{name}", fn ->
      if pid = Process.whereis(name) do
        Process.exit(pid, :shutdown)
      end
    end)

    name
  end

  @doc false
  # Schedules a cache to be deleted at the end of the current test context.
  def reset_caches do
    reset = fn ->
      Cachex.reset(Sentix)
    end
    reset.()
    ExUnit.Callbacks.on_exit(reset)
  end

end

# start tests
ExUnit.start()
