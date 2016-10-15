defmodule Sentix.CacheTest do
  use ExUnit.Case

  # This test ensures that we can locate binaries on the system using a cached
  # version to speed up the retrieval. We test both an existing and missing binaries.
  # in order to make sure that we can safely handle missing executables.
  test "locates a binary" do
    # schedule cache cleanup
    TestHelper.reset_caches()

    # search for an existing and then missing binary
    { :ok, loc } = Sentix.Cache.find_binary('fswatch')
    { :error, msg } = Sentix.Cache.find_binary('yolo-sentix')

    # verify we find the fswatch binary
    assert(loc != false)
    assert(String.ends_with?(loc, "fswatch"))

    # verify the second binary is missing
    assert(msg == :missing_binary)
  end

  # This test covers the addition of subscribers to a cache backing Sentix to
  # ensure that a restarted Watcher can still gain control of the processes it
  # needs to be sending updates to. We also make sure to work with missing procs
  # just to make sure that we don't crash accidentally.
  test "working with subscribers in a cache" do
    # schedule cache cleanup
    TestHelper.reset_caches()

    # create a base subscriber list
    subscribers = []

    # add a new subscriber
    subscribers1 = Sentix.Cache.add_subscriber(:test_proc, subscribers, :new_sub)
    subscribers2 = Sentix.Cache.add_subscriber(:test_proc, subscribers1, :new_sub)
    subscribers3 = Sentix.Cache.add_subscriber(:test_proc, subscribers2, :old_sub)

    # verify the first two return values match
    assert(subscribers1 == [ :new_sub ])
    assert(subscribers2 == [ :new_sub ])

    # verify the third has both subscribers
    assert(subscribers3 == [ :old_sub, :new_sub ])

    # retrieve the cached subscribers
    subscribers4 = Sentix.Cache.get_subscribers(:test_proc)

    # verify this represents the last set
    assert(subscribers4 == subscribers3)

    # ask for subscribers rfrom a missing watcher
    subscribers5 = Sentix.Cache.get_subscribers(:missing)

    # should return an empty list
    assert(subscribers5 == [ ])
  end

end
