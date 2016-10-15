defmodule Sentix.BridgeTest do
  use ExUnit.Case

  # Ensures that we can convert event names between `fswatch` and `atom` names,
  # by using both camelCase and snake_case to formatting. Atoms should be in
  # the latter case, fswatch in the former.
  test "converts between fswatch and atomic names" do
    # create some names of both types
    name1 = "IsFile"
    name2 = :is_file

    # convert both to the opposite type
    result1 = Sentix.Bridge.convert_name(name1, "atom")
    result2 = Sentix.Bridge.convert_name(name2, "binary")

    # convert to the same type
    result3 = Sentix.Bridge.convert_name(name1, "binary")
    result4 = Sentix.Bridge.convert_name(name2, "atom")

    # automatic conversion
    result5 = Sentix.Bridge.convert_name(name1)
    result6 = Sentix.Bridge.convert_name(name2)

    # the first two should be inverted
    assert(result1 == name2)
    assert(result2 == name1)

    # the second two should be identical
    assert(result3 == name1)
    assert(result4 == name2)

    # the final two should also be inverted
    assert(result5 == name2)
    assert(result6 == name1)
  end

  # Uses the Bridge to locate the port we need to execute with. Upstream names
  # ports in an unreliable manner, so we need to do a search to make sure we
  # find the port correctly, rather than just trusting upstream to find it.
  test "locates a port driver" do
    # find the priv directory
    priv = to_string(:code.priv_dir(:erlexec))

    # pull back a port driver
    port = Sentix.Bridge.locate_port()

    # it should be a charlist
    assert(is_list(port))

    # convert to String
    port = to_string(port)

    # it should be in priv
    assert(String.starts_with?(port, priv))

    # it should end with exec-port
    assert(String.ends_with?(port, "exec-port"))
  end

end
