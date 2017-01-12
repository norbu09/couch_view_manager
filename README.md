# CouchViewManager

The CouchViewManager is a handy way to manage your CouchDB views in
projects. It expects a directory with view modules and functions that
emit the views that should be present in CouchDB. It then cehcks the
respective DB for those views and adds missing ones, updates existing
ones that have changed and ignores the ones that match the code.

I use it in a few projects to manage views for Phoenix projects where I
want to make sure that all devs, staging and production all have the
same views defined.

It will not remove additional views that might be present so you can
test around locally and once things work, add them to the code base so
everyone starts to see the new view. It also makes sure that the views
are managed by version control so they can easily be rolled back if
needed.

## Installation

The package can be installed as:

  1. Add `couch_view_manager` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:couch_view_manager, github: "norbu09/couch_view_manager"}]
    end
    ```

  2. Ensure `couch_view_manager` is started before your application:

    ```elixir
    def application do
      [applications: [:couch_view_manager]]
    end
    ```

## Usage

I use CouchViewManager in OTP apps this way:

In the main start function add a call to `migrate` 

   ```elixir
  def start(_type, _args) do
    ...
    Task.async(fn -> CouchViewManager.migrate() end)
    ...
  end
  ```

Then make sure you have a `lib/views` directory with a bunch of files
that look like this:

   ```elixir
    defmodule Views.User do
      def by_email do
        %{doc:  "_design/user",
          db:   "test",
          view: "by_email",
          map:  "function(doc) {\n  if(doc.type == \"user\"){\n    emit(doc.email, null);\n  }\n}"
        }
      end
      def is_admin do
        %{doc:  "_design/user",
          db:   "test",
          view: "is_admin",
          map:  "function(doc) {\n  if(doc.is_admin){\n    emit(doc.email, null);\n  }\n}"
        }
      end
    end
   ```

They need to have the keys `doc`, `db`, `view` and `map` defined.

