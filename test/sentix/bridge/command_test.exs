defmodule Sentix.Bridge.CommandTest do
  use ExUnit.Case

  # This test verifies the ability to flatten provided arguments to a command
  # by using a binary, options and target directories. The result should have
  # the executable as first argument, options as middle arguments, and the last
  # argument should be target directories to watch.
  test "flattening a command structure" do
    # our binary to execute
    executable = "/usr/bin/fswatch"

    # parse out some options
    options = Sentix.Bridge.Options.parse!([ recursive: true ])

    # our target directory
    targets = "/tmp/watched_directory"

    # flatten the arguments to a generated command
    results = Sentix.Bridge.Command.generate!(executable, options, targets)

    # ensure the conversion translates correctly
    assert(results == [
      '/usr/bin/fswatch',
      '-r',
      '-x',
      '--event-flag-separator=__stx__',
      '/tmp/watched_directory'
    ])
  end

end
