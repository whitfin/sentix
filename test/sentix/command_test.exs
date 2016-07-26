defmodule Sentix.CommandTest do
  use ExUnit.Case

  alias Sentix.Bridge.{
    Command, Options
  }

  test "can locate the fswatch binary" do
    on_exit(fn ->
      Cachex.reset(Sentix)
    end)

    { :ok, loc } = Command.locate_fswatch()

    assert(loc != false)
    assert(String.ends_with?(loc, "fswatch"))
  end

  test "can flatten a command structure" do
    binary  = "/usr/bin/fswatch"
    options = Options.parse!([ recursive: true ])
    targets = "/tmp/watched_directory"

    assert(Command.generate!(binary, options, targets) == [
      '/usr/bin/fswatch',
      '-x',
      '-r',
      '/tmp/watched_directory'
    ])
  end

end
