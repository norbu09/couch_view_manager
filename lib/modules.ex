defmodule Modules do

  defmacro views() do
    quote do
      Application.get_env(:couch_view_manager, :views)
      |> Enum.map(&(String.capitalize(&1)))
      |> Enum.map(fn(x) -> Module.concat(Views, x) end)
      |> Enum.map(&(%{&1 => apply(&1, :__info__, [:functions])}))
    end
  end
  
end
