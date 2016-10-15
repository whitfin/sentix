defmodule SentixTest do
  use ExUnit.Case

  # enable doctests
  doctest Sentix

  # This test covers simply starting Sentix with both a valid and invalid path
  # to watch. If the path is valid, we should receive a pid back to monitor, and
  # if it's invalid we should receive an invalid_path  error Tuple.
  test "creating a new Sentix watcher" do
    # create a watcher name
    name1 = TestHelper.create_name()

    # create another watcher name
    name2 = TestHelper.create_name()

    # create a valid watcher
    { status1, value1 } = Sentix.start(name1, "/tmp/watched_directory")

    # verify everything looks ok
    assert(status1 == :ok)
    assert(is_pid(value1))

    # create a watcher with an invalid path
    { status2, value2 } = Sentix.start(name2, :missing)

    # it should return an error
    assert(status2 == :error)
    assert(value2 == :invalid_path)
  end

  # This test ensures that we can subscribe a process to a Sentix watcher. We
  # only check for invalid and valid processes here, as tests for the actual
  # watcher are written separately to avoid bloating test logic.
  test "subscribing a process for notifications" do
    # create a watcher name
    name = TestHelper.create_name()

    # start a Sentix watch
    { status, value } = Sentix.start(name, "/tmp/watched_file")

    # verify everything worked
    assert(status == :ok)
    assert(is_pid(value))

    # subscribe the current process
    { status, process, subscribers } = Sentix.subscribe(name)

    # ensure we subscribed corretly
    assert(status == :ok)
    assert(is_number(process))
    assert(subscribers == [ self() ])

    # subscribe a missing process
    result = Sentix.subscribe(name, :missing)

    # it should error
    assert(result == { :error, :noproc })
  end

end
