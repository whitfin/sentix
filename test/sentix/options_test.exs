defmodule Sentix.OptionsTest do
  use ExUnit.Case

  alias Sentix.Bridge.Options

  test "parses out a truthy :access option" do
    assert(Options.parse!([ access:  true ]) == add_defaults([ "-a" ]))
  end

  test "parses out a falsey :access option" do
    assert(Options.parse!([ access: false ]) == add_defaults([ ]))
  end

  test "parses out a truthy :dir_only option" do
    assert(Options.parse!([ dir_only:  true ]) == add_defaults([ "-d" ]))
  end

  test "parses out a falsey :dir_only option" do
    assert(Options.parse!([ dir_only: false ]) == add_defaults([ ]))
  end

  test "parses out the :excludes option" do
    assert(Options.parse!([ excludes: "/test.*/" ]) == add_defaults([ "-e", "/test.*/" ]))
  end

  test "parses out a :filter option with a single event" do
    assert(Options.parse!([ filter: :created ]) == add_defaults([ "--event=Created" ]))
  end

  test "parses out a :filter option with multiple events" do
    assert(Options.parse!([ filter: [ :created, :renamed ] ]) == add_defaults([ "--event=Created", "--event=Renamed" ]))
  end

  test "parses out a :filter option with non-atom events" do
    assert(Options.parse!([ filter: [ "Created", "Renamed" ] ]) == add_defaults([ "--event=Created", "--event=Renamed" ]))
  end

  test "parses out the :includes option" do
    assert(Options.parse!([ includes: "/test.*/" ]) == add_defaults([ "-i", "/test.*/" ]))
  end

  test "parses out the :latency option" do
    assert(Options.parse!([ latency: 0.1 ]) == add_defaults([ "-l", "0.1" ]))
  end

  test "parses out an invalid :latency option" do
    assert(Options.parse!([ latency: 1.1 ]) == add_defaults([ ]))
  end

  test "parses out the :monitor option" do
    assert(Options.parse!([ monitor: "fsevents_monitor" ]) == add_defaults([ "-m", "fsevents_monitor" ]))
  end

  test "parses out a truthy :recursive option" do
    assert(Options.parse!([ recursive:  true ]) == add_defaults([ "-r" ]))
  end

  test "parses out a falsey :recursive option" do
    assert(Options.parse!([ recursive: false ]) == add_defaults([ ]))
  end

  test "parses out a list of many options" do
    opts = [
      access: true,
      dir_only: true,
      excludes: "/test.*/",
      filter: [ :created, :renamed ],
      includes: "/test.*/",
      latency: 0.1,
      monitor: "fsevents_monitor",
      recursive: true
    ]

    assert(Options.parse!(opts) == add_defaults([
      "-a",
      "-d",
      "-e", "/test.*/",
      "--event=Created",
      "--event=Renamed",
      "-i", "/test.*/",
      "-l", "0.1",
      "-m", "fsevents_monitor",
      "-r"
    ]))
  end

  defp add_defaults(opts) do
    [ "-x" | opts ]
  end

end
