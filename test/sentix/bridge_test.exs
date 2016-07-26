defmodule Sentix.BridgeTest do
  use ExUnit.Case

  alias Sentix.Bridge

  test "converts an fswatch name to an atom" do
    assert(Bridge.convert_name("IsFile", "atom") == :is_file)
  end

  test "converts an atom to an fswatch name" do
    assert(Bridge.convert_name(:is_file, "binary") == "IsFile")
  end

  test "skips conversion when the style is already formed" do
    assert(Bridge.convert_name(:is_file, "atom") == :is_file)
    assert(Bridge.convert_name("IsFile", "binary") == "IsFile")
  end

end
