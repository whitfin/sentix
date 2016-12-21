defmodule Sentix.WatcherTest do
  use ExUnit.Case

  # we need log captures
  import ExUnit.CaptureLog

  # This test makes sure that we forward stderr to the Logger so that a user can
  # see it in their logs instead of swallowing it and ignoring it. We test this
  # just by using invalid options which will kill the port.
  test "forwarding stderr to the Logger" do
    # create a watcher name
    name = TestHelper.create_name()

    # start a watcher with invalid options
    io_output = capture_log(fn ->
      # start with an invalid monitor flag
      Sentix.start(name, "/tmp", monitor: :missing)
      # sleep to ensure we grab the log
      :timer.sleep(100)
    end)

    # verify the error message
    assert(io_output =~ "[error] Invalid monitor name.")
    assert(io_output =~ "[error] GenServer :#{name} terminating")
    assert(io_output =~ "** (stop) :port_terminated")

    # find the watcher
    whereis = Process.whereis(name)

    # it shouldn't be found
    assert(whereis == nil)
  end

  # This test covers subscribing to a watcher process and receiving a notification
  # for a touch event on a file. We just create a file and write it in order to
  # make sure that we see the notification coming back to the Erlag mailboxes.
  # We also add a dead subscriber to make sure that it is correctly removed with
  # no issue in order to make sure we don't notify dead processes.
  test "subscribing and receiving messages" do
    # create a watcher name
    name = TestHelper.create_name()

    # start a Sentix watcher
    { status, value } = Sentix.start(name, "/tmp", latency: 0.1)

    # verify everything worked
    assert(status == :ok)
    assert(is_pid(value))

    # register this process
    Process.register(self(), :watcher_caller)

    # subscribe the current process
    { status, process, subscribers } = Sentix.subscribe(name, :watcher_caller)

    # ensure we subscribed corretly
    assert(status == :ok)
    assert(is_number(process))
    assert(subscribers == [ :watcher_caller ])

    # create a new agent with a name
    { :ok, pid } = Agent.start(fn -> 1 end, name: :tmp_agent)

    # subscribe the agent too
    { status, process, subscribers } = Sentix.subscribe(name, :tmp_agent)

    # we should have two subscriptions now
    assert(status == :ok)
    assert(is_number(process))
    assert(subscribers == [ :tmp_agent, :watcher_caller])

    # kill the agent subscriber
    Process.exit(pid, :kill)

    # touch our file
    touch_file("/tmp/watched file")

    # we can't match events on all platforms here
    receive do
      msg ->
        # break down the received message
        { proc, { :fswatch, :file_event }, { file, events } } = msg

        # verify all flags are correct
        assert(proc == process)
        assert(file =~ "/tmp/watched file")
        assert(:created in events)

        # retrieve subscribers
        subscribers = Sentix.Cache.get_subscribers(name)

        # verify the agent was removed
        assert(subscribers == [ :watcher_caller ])
    after
      1000 ->
        # explode if we don't have a response within a second
        flunk("Should have received a notification!")
    end
  end

  # The watcher process needs to be linked to the port, so that it dies when the
  # port dies in order to allow the user to restart the port properly. This test
  # just makes sure that killing the port process means that the watcher process
  # dies so that it can be restarted correctly by a Supervision tree.
  test "terminating when the port dies" do
    # create a watcher name
    name = TestHelper.create_name()

    # start a watcher
    { status, value } = Sentix.start(name, "/tmp")

    # verify everything worked
    assert(status == :ok)
    assert(is_pid(value))

    # subscribe the current process
    { status, process, subscribers } = Sentix.subscribe(name)

    # ensure we subscribed corretly
    assert(status == :ok)
    assert(is_number(process))
    assert(subscribers == [ self() ])

    # kill the process to generate stderr
    io_output = capture_log(fn ->
      # kill using a -9, because why not
      System.cmd("kill", [ "-9", "#{process}" ])
      # sleep for a few millis for log capture
      :timer.sleep(5)
    end)

    # verify the error messages
    assert(io_output =~ "[error] GenServer :#{name} terminating")
    assert(io_output =~ "** (stop) :port_terminated")

    # find the watcher
    whereis = Process.whereis(name)

    # it shouldn't be found
    assert(whereis == nil)
  end

  # This function touches a given file name by creating it. We also schedule it
  # to be deleted at the end of the test to make sure we don't leave anything
  # laying around when it's not needed.
  defp touch_file(file) do
    # schedule a removal
    on_exit(fn ->
      # force remove the file
      File.rm!(file)
    end)

    # sleep for a little bit
    :timer.sleep(150)

    # touch the file with a bit of input
    File.write!(file, "input")
  end

end
