defmodule Sentix.Cache do
  @moduledoc """
  This module just provides a cache interface which can back multiple Sentix
  watchers, to make sure that we have some form of persistence (rather than
  relying on the developer to remember to reconnect on crashes).

  Currently the only provided functions are based around subscriber storage (in
  order to persist across crashes), and paths of binaries to avoid having to look
  for them on every execution.
  """

  @doc """
  Adds a subscriber against the provided Sentix name.

  This is a convenience method to avoid having to check whether the list includes
  the provided subscriber every time we wish to add a subscriber (because we
  don't want to duplicate messages to the subscriber).
  """
  @spec add_subscriber(name :: atom, subs :: [ pid ], sub :: pid) :: subs :: [ pid ]
  def add_subscriber(name, subs, sub) do
    sub_list = if Enum.member?(subs, sub) do
      subs
    else
      [ sub | subs ]
    end
    set_subscribers(name, sub_list)
  end

  @doc """
  Retrieves the list of subscribers for a provided Sentix name.

  This simply hits the backing cache for the provided name, and returns an empty
  list if the name does not exist inside the cache.
  """
  @spec get_subscribers(name :: atom) :: subscribers :: [ pid ]
  def get_subscribers(name) do
    Cachex.get!(Sentix, name) || []
  end

  @doc """
  Sets the subscribers for a given Sentix watcher.

  This will write the subscribers into the cache, and then return the list of
  persisted subscribers for convenience.
  """
  @spec set_subscribers(name :: atom, subscribers :: [ pid ]) :: subscribers :: [ pid ]
  def set_subscribers(name, subscribers) do
    Cachex.set!(Sentix, name, subscribers) && subscribers
  end

  @doc """
  Locates a binary on the host system, if possible.

  Once the binary has been located, it's stored inside the cache to speed up future
  lookups. We use `:os.find_executable/1` under the hood to locate the binary.
  """
  @spec find_binary(name :: [ char ]) ::
        { :ok, path :: binary } |
        { :error, reason :: binary }
  def find_binary(name) do
    case Cachex.get!(Sentix, name, fallback: &do_find_binary/1) do
      nil -> { :error, :missing_binary }
      val -> { :ok, val }
    end
  end

  # Internal fallback function for use when a binary has no entry inside the
  # cache. This function is used to generate the initial entry for the cache.
  defp do_find_binary(key) do
    case :os.find_executable(key) do
      false -> nil
      value -> to_string(value)
    end
  end

end
