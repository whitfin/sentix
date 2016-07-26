defmodule SentixTest do
  use ExUnit.Case
  doctest Sentix

  setup do
    letters =
      ?a..?z
      |> Enum.to_list

    name =
      1..16
      |> Enum.map(fn(_) -> Enum.random(letters) end)
      |> List.to_string
      |> String.to_atom

    on_exit("kill #{name}", fn ->
      if pid = Process.whereis(name) do
        Process.exit(pid, :shutdown)
      end
    end)

    { :ok, name: name }
  end

  test "start_link/3 creates a new Sentix watcher", state do
    { status, value } = Sentix.start(state.name, "/tmp/watched_directory")
    assert(status == :ok)
    assert(is_pid(value))
  end

  test "start_link/3 errors when invalid paths are provided", state do
    assert(Sentix.start(state.name, :missing) == { :error, :invalid_path })
  end

  test "subscribe/2 registers a process for notifications", state do
    { status, value } = Sentix.start(state.name, "/tmp/watched_file")

    assert(status == :ok)
    assert(is_pid(value))

    { status, process, subscribers } = Sentix.subscribe(state.name)

    assert(status == :ok)
    assert(is_number(process))
    assert(subscribers == [ self() ])
  end

  test "subscribe/2 returns an error for an invalid process", state do
    { status, value } = Sentix.start(state.name, "/tmp/watched_file")

    assert(status == :ok)
    assert(is_pid(value))
    assert(Sentix.subscribe(state.name, :missing) == { :error, :noproc })
  end

end
