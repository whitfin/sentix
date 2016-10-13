# Sentix
[![Build Status](https://img.shields.io/travis/zackehh/sentix.svg)](https://travis-ci.org/zackehh/sentix) [![Coverage Status](https://img.shields.io/coveralls/zackehh/sentix.svg)](https://coveralls.io/github/zackehh/sentix) [![Hex.pm Version](https://img.shields.io/hexpm/v/sentix.svg)](https://hex.pm/packages/sentix) [![Documentation](https://img.shields.io/badge/docs-latest-yellowgreen.svg)](https://hexdocs.pm/sentix/)

Sentix is a file system watcher based on [fswatch](https://github.com/emcrisostomo/fswatch). It provides a stable port binding around `fswatch` (with configurable arguments) and translates the output to messages that are easy to work with from inside Elixir. Naturally, it goes without saying that you need `fswatch` installed to use this tool properly.

## Installation

Sentix is available in Hex so you can install it pretty easily:

  1. Add `sentix` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:sentix, "~> 1.0"}]
    end
    ```

  2. Ensure `sentix` is started before your application:

    ```elixir
    def application do
      [applications: [:sentix]]
    end
    ```

As previously mentioned, installing `fswatch` is a pre-req for using Sentix.

## Usage

### Startup

It's likely that you'll want to setup Sentix inside a Supervisor to ensure fault-tolerance. This can be done as follows:

```elixir
Supervisor.start_link(
  [ worker(Sentix, [ :watcher_name, [ "/path/to/watch" ] ]) ]
)
```

Of course you can also start it manually using `Sentix.start_link(:watcher_name, [ "/path/to/watch" ])`.

The first two arguments to `Sentix.start_link/3` are a name for the Sentix watcher and a list of paths to watch (or a single path, whichever). The third parameter is a list of options which are passed through the `fswatch` port. Please see the [documentation](https://hexdocs.pm/sentix/Sentix.html#start_link/3) for `Sentix.start_link/3` for a full list of options which can be used.

### Subscribing

Once you have a Sentix watcher running, you can subscribe processes to it to receive the forwarded notifications through the port. This is done using `Sentix.subscribe/2`:

```elixir
Sentix.subscribe(:watcher_name)          # subscribes the calling process
Sentix.subscribe(:watcher_name, :sub)    # subscribe by a process name
Sentix.subscribe(:watcher_name, self())  # subscribe using a pid
```

A watcher can have any number of subscribers, but remember that more subscribers will result in a longer latency to pickup changes - so it may be that you need to implement grouping if you have a large number of subscribers.

In the case that a subscribed process is not alive when a message comes in, it will be removed from the watcher subscription list to avoid repeatedly sending messages that will never be received. In addition, an ETS cache is used to persist subscribers across restarts in case the watcher has to restart for any reason - so you don't need to subscribe again if the watcher dies (although you can do so just to be certain, watchers do not store duplicates).

### Receiving Notifications

Once subscribed, you'll receive messages of the following format:

```elixir
{ os_process_pid, { :fswatch, :file_event }, { file_path, event_list } }
```

The file path is naturally the path of the file which has been affected by a filesystem event. The list of events contains the events passed through by `fswatch`. Please note that these events are modified to atoms instead of the raw names from `fswatch`. For example, the `IsFile` event becomes `:is_file` in Sentix.

This message format is inspired by that of the [fs](https://github.com/synrc/fs) library to make it possible for developers to migrate between the two projects easily.

## Contributions

The Sentix API is deliberately tiny, as we leverage `fswatch` to do most of the work. If you have any feature requests, please make sure that it can be supported via the current `fswatch` API, or can easily be implemented (with low cost) on top of the API. Aside from this, please feel free to file an issue if you feel that something can be improved.

If you file any PRs, you can use the commands below to verify the test coverage of your changes, and the quality of your code (as measured by Credo).

```bash
$ mix test
$ mix credo
$ mix coveralls
```
