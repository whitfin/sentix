defmodule Sentix.Bridge.OptionsTest do
  use ExUnit.Case

  # This test covers any options which only accept boolean values, and ensures
  # that they parse correctly and add a switch to the command generated. All of
  # the below options function the same way so we can just include them in one
  # test and make sure that they all work the same way.
  test "parses out boolean options" do
    # define a validation function
    test_boolean_flag = fn(flag, switch) ->
      # parse out various flag values
      result1 = Sentix.Bridge.Options.parse!([ { flag,  true } ])
      result2 = Sentix.Bridge.Options.parse!([ { flag, false } ])

      # the first should have the switch
      assert(result1 == add_defaults([ switch ]))

      # the second should be simply defaults
      assert(result2 == add_defaults([ ]))
    end

    # test :access, :dir_only and :recursive
    test_boolean_flag.(:access, "-a")
    test_boolean_flag.(:dir_only, "-d")
    test_boolean_flag.(:recursive, "-r")
  end

  # This test covers options which have a value set against them, and makes sure
  # that they all parse correctly and add a switch with a value to the generated
  # command. Like the boolean test, all of these options work the same way so we
  # group them to avoid duplicating a lot of test code unnecessarily.
  test "parse out flagged options" do
    # define a validation function
    test_flag_option = fn(flag, switch, value) ->
      # parse out the flag vlue
      result = Sentix.Bridge.Options.parse!([ { flag, value } ])

      # the first should have the switch
      assert(result == add_defaults([ switch, value ]))
    end

    # test :excludes, :includes and :monitor
    test_flag_option.(:excludes, "-e", "/test.*/")
    test_flag_option.(:includes, "-i", "/test.*/")
    test_flag_option.(:monitor,  "-m", "fsevents_monitor")
  end

  # This test covers the filter for events raised by fswatch. We accept either
  # a single filter or a list, and they can be either Sentix atoms or fswatch
  # binary labels (as we convert internally). This flag is of the for --x=y and
  # so it doesn't fit into the test above easily, and so is abstracted out.
  test "parses out a :filter option" do
    # parse out with a single event
    result1 = Sentix.Bridge.Options.parse!([ filter: :created ])

    # parse with multiple events
    result2 = Sentix.Bridge.Options.parse!([ filter: [ :created, :renamed ] ])

    # parse with binary event names
    result3 = Sentix.Bridge.Options.parse!([ filter: [ "Created", "Renamed" ] ])

    # the first should have --event=Created
    assert(result1 == add_defaults([ "--event=Created" ]))

    # the second should have --event=Created and --event=Renamed
    assert(result2 == add_defaults([ "--event=Created", "--event=Renamed" ]))

    # the third should be identical to the second
    assert(result3 == result2)
  end

  # The latency option must be a decimal between 0.1 and 1.0 (inclusive). This
  # test just makes sure that this parses and correctly enforces the bounds as
  # it should. The valid bound should be set against the "-l" flag.
  test "parses out the :latency option" do
    # parse with a valid latency
    result1 = Sentix.Bridge.Options.parse!([ latency: 0.1 ])

    # parse with an invalid latency
    result2 = Sentix.Bridge.Options.parse!([ latency: 1.1 ])

    # the first should use `-l 0.1`
    assert(result1 == add_defaults([ "-l", "0.1" ]))

    # the second should be ignored
    assert(result2 == add_defaults([ ]))
  end

  # Just for safety, we make sure to also parse a large list of many options just
  # to make sure that they all make the options list correctly and in order (but
  # the order is a side effect, not required by any means).
  test "parses out a combination of options" do
    # define a list of all options
    options = [
      access: true,
      dir_only: true,
      excludes: "/test.*/",
      filter: [ :created, :renamed ],
      includes: "/test.*/",
      latency: 0.1,
      monitor: "fsevents_monitor",
      recursive: true
    ]

    # parse the option list
    result = Sentix.Bridge.Options.parse!(options)

    # verify everything is correctly formed
    assert(result == add_defaults([
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

  # Just adds default arguments to the provided options, rather than having to
  # keep writing it out and potentially not getting it correct.
  defp add_defaults(opts), do: opts ++ Sentix.Bridge.Options.defaults()

end
