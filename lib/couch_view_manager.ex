defmodule CouchViewManager do
  require Logger
  require Modules
  @db Application.get_env(:couchex, :db)

  def migrate do
    case @db do
      nil -> 
        Logger.warn("No DB configured for couch_view_manager")
        Logger.warn("Config is: #{inspect Application.get_all_env(:couchex)}")
        :ok
      "" -> 
        Logger.warn("No DB configured (empty string) for couch_view_manager")
        Logger.warn("Config is: #{inspect Application.get_all_env(:couchex)}")
        :ok
      db -> 
        Couchex.Client.create_db(db)
        Modules.views() |> Enum.map(&check(&1))
    end
  end

  def check(views) do
    [module] = Map.keys(views)
    Logger.debug("module: #{inspect(module)}")

    Enum.map(views[module], fn {x, _y} -> apply(module, x, []) end)
    |> List.flatten()
    |> Enum.map(&check_doc(&1))
  end

  def check_doc(%{doc: doc, view: view, map: map, db: db} = ddoc) do
    {:ok, design_doc} = check_or_create_doc(db, doc)
    views = check_or_create_view(design_doc["views"], view, map)

    views1 =
      case ddoc[:reduce] do
        nil ->
          views

        reduce ->
          check_view_detail(views, view, reduce, "reduce")
      end

    new_doc = %{design_doc | "views" => views1}

    case new_doc == design_doc do
      false ->
        Logger.debug("updating design doc #{doc} with views: #{inspect(views1)}")
        Couchex.Client.put(db, new_doc)

      true ->
        Logger.debug("no need to update - #{doc} is current")
    end
  end

  def check_doc(%{doc: doc, list: list, function: function, db: db} = _ddoc) do
    {:ok, design_doc} = check_or_create_doc(db, doc)
    lists = check_or_create_list(design_doc["lists"] || %{}, list, function)
    new_doc = Map.put(design_doc, "lists", lists)

    case new_doc == design_doc do
      false ->
        Logger.debug("updating design doc #{doc} with lists: #{inspect(lists)}")
        Couchex.Client.put(db, new_doc)

      true ->
        Logger.debug("no need to update - #{doc} is current")
    end
  end

  def check_doc(ddoc) do
    check_doc(Map.put(ddoc, :db, @db))
  end

  # internal functions
  defp check_or_create_view(views, view, map) do
    Logger.debug("map: #{inspect(map)}")
    Logger.debug("view: #{inspect(views[view]["map"])}")

    case views[view] do
      nil ->
        Logger.debug("adding view #{view}")
        Map.put(views, view, %{"map" => map})

      _ ->
        views
        |> check_view_detail(view, map, "map")
    end
  end

  defp check_view_detail(views, name, thing, type) do
    case views[name][type] == thing do
      true ->
        Logger.debug("have #{type} #{name} already ... skipping")
        views

      false ->
        Logger.debug("#{name} needs updating %{#{type} => #{thing}}")
        map = Map.merge(views[name] || %{}, %{type => thing})
        Map.put(views, name, map)
    end
  end

  defp check_or_create_list(lists, list, function) do
    Logger.debug("list: #{inspect(lists[list])}")

    case lists[list] do
      nil ->
        Logger.debug("adding list #{list}")
        Map.put(lists, list, function)

      _ ->
        case lists[list] == function do
          true ->
            Logger.debug("have list already ... skipping")

          false ->
            Logger.debug("#{list} needs updating")
            Map.put(lists, list, function)
        end

        lists
    end
  end

  defp check_or_create_doc(db, doc) do
    case Couchex.Client.get(db, doc) do
      {:ok, exists} ->
        Logger.debug("Found design doc: #{doc}")
        {:ok, exists}

      {:error, {{:http_status, 404}, _}} ->
        Logger.debug("Need to create new design doc: #{doc}")
        {:ok, %{"_id" => doc, "language" => "javascript", "views" => %{}}}

      error ->
        error
    end
  end
end
