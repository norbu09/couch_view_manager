defmodule CouchViewManager do

  require Logger

  def migrate do
    case File.ls("lib/views") do
      {:ok, list} ->
        list
        |> Enum.filter(&(String.ends_with?(&1, ".ex")))
        |> Enum.map(&(String.trim_trailing(&1, ".ex")))
        |> Enum.map(&(String.capitalize(&1)))
        |> Enum.map(fn(x) -> Module.concat(Views, x) end)
        |> Enum.map(&(%{&1 => apply(&1, :__info__, [:functions])}))
        |> Enum.map(&(check(&1)))
      error -> error
    end
  end

  def check(views) do
    [module] = Map.keys(views)
    Enum.map(views[module], fn(x) -> apply(module, x, []) end)
    |> List.flatten
    |> Enum.map(&(check_doc(&1)))
  end

  def check_doc(%{doc: doc, view: view, map: map, db: db} = _ddoc) do
    {:ok, view_doc} = check_or_create_doc(db, doc)
    views = check_or_create_view(view_doc["views"], view, map)
    new_doc = %{view_doc | "views" => views}
    case new_doc == view_doc do
      false ->
        Logger.debug("updating design doc #{doc} with views: #{inspect views}")
        Couchex.Client.put(db, new_doc)
      true ->
        Logger.debug("no need to update - #{doc} is current")
    end
  end

  # internal functions
  defp check_or_create_view(views, view, map) do
    case views[view] do
      nil ->
        Logger.debug("adding view #{view}")
        Map.put(views, view, %{"map" => map})
      _ ->
        Logger.debug("have view already ... skipping")
        views
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
      error -> error
    end
  end

end
