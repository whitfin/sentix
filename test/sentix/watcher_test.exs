defmodule Sentix.WatcherTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  alias Sentix.Cache

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

  test "watcher is able to receive messages from fswatch", state do
    { status, value } = Sentix.start(state.name, "/tmp", latency: 0.1)
    assert(status == :ok)
    assert(is_pid(value))

    Process.register(self(), :test_subscriber)

    { status, process, subscribers } = Sentix.subscribe(state.name, :test_subscriber)

    assert(status == :ok)
    assert(is_number(process))
    assert(subscribers == [ :test_subscriber ])

    touch_file("/tmp/watched_file")

    receive do
      msg ->
        { proc, { :fswatch, :file_event }, { file, events } } = msg

        assert(proc == process)
        assert(file =~ "/tmp/watched_file")
        assert(:created in events)
    after
      1000 ->
        flunk("Should have received a notification!")
    end
  end

  test "watcher trims dead subscribers on notifications", state do
    { status, value } = Sentix.start(state.name, "/tmp", latency: 0.1)
    assert(status == :ok)
    assert(is_pid(value))

    { status, process, subscribers } = Sentix.subscribe(state.name)

    assert(status == :ok)
    assert(is_number(process))
    assert(subscribers == [ self() ])

    { :ok, pid } = Agent.start(fn -> 1 end, name: :tmp_agent)
    { status, process, subscribers } = Sentix.subscribe(state.name, :tmp_agent)

    assert(status == :ok)
    assert(is_number(process))
    assert(subscribers == [ :tmp_agent, self() ])

    Process.exit(pid, :kill)

    touch_file("/tmp/watched_file")

    receive do
      msg ->
        { proc, { :fswatch, :file_event }, _payload } = msg
        assert(Cache.get_subscribers(state.name) == [ self() ])
    after
      1000 ->
        flunk("Should have received a notification!")
    end
  end

  test "watcher forwards all stderr to the Logger", state do
    io_output = capture_log(fn ->
      Sentix.start(state.name, "/tmp", monitor: :missing)
      :timer.sleep(100)
    end)

    assert(io_output =~ "[error] Invalid monitor name.")
    assert(io_output =~ "[error] GenServer :#{state.name} terminating")
    assert(io_output =~ "** (stop) :port_terminated")

    assert(Process.whereis(state.name) == nil)
  end

  test "watcher terminates when the port dies", state do
    { status, value } = Sentix.start(state.name, "/tmp")
    assert(status == :ok)
    assert(is_pid(value))

    { status, process, subscribers } = Sentix.subscribe(state.name)

    assert(status == :ok)
    assert(is_number(process))
    assert(subscribers == [ self() ])

    io_output = capture_log(fn ->
      System.cmd("kill", [ "-9", "#{process}" ])
      :timer.sleep(5)
    end)

    assert(io_output =~ "[error] GenServer :#{state.name} terminating")
    assert(io_output =~ "** (stop) :port_terminated")

    assert(Process.whereis(state.name) == nil)
  end

  defp touch_file(file) do
    on_exit(fn ->
      File.rm!(file)
    end)

    :timer.sleep(150)

    File.write!(file, "input")
  end

end
