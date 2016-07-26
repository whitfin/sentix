defmodule Sentix.CacheTest do
  use ExUnit.Case

  alias Sentix.Cache

  test "locates a binary" do
    on_exit(fn ->
      Cachex.reset(Sentix)
    end)

    { :ok, loc } = Cache.find_binary('fswatch')

    assert(loc != false)
    assert(String.ends_with?(loc, "fswatch"))
  end

  test "errors on a missing binary" do
    on_exit(fn ->
      Cachex.reset(Sentix)
    end)

    assert(Cache.find_binary('yolo') == { :error, "yolo not found on system, is it installed?" })
  end

  test "adds a subscriber to the cache" do
    on_exit(fn ->
      Cachex.reset(Sentix)
    end)

    result = Cache.add_subscriber(:test_proc, [], :new_subscriber)
    assert(result == [ :new_subscriber ])

    subscribers = Cache.get_subscribers(:test_proc)
    assert(subscribers == [ :new_subscriber ])
  end

  test "does not add duplicate subscribers" do
    on_exit(fn ->
      Cachex.reset(Sentix)
    end)

    result = Cache.add_subscriber(:test_proc, [ :new_subscriber ], :new_subscriber)
    assert(result == [ :new_subscriber ])

    subscribers = Cache.get_subscribers(:test_proc)
    assert(subscribers == [ :new_subscriber ])
  end

  test "returns an empty list for a missing watcher" do
    on_exit(fn ->
      Cachex.reset(Sentix)
    end)

    subscribers = Cache.get_subscribers(:missing)
    assert(subscribers == [ ])
  end

end
