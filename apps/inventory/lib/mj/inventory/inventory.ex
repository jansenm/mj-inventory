# SPDX-FileCopyrightText: 2021 2021 Michael Jansen <info@michael-jansen.biz>
#
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# Copyright (C) 2021 Michael Jansen <info@michael-jansen.biz>
#
# This software is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# This software is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <https://www.gnu.org/licenses/>. 

defmodule MJ.Inventory do
  @moduledoc """
  Inventory encapsulates everything that defines a Inventory.
  """

  use GenServer

  alias MJ.Inventory.Types.{Class, Node}
  alias MJ.Inventory.Registry
  alias MJ.Inventory.Cache
  alias MJ.Inventory.Inheritance
  alias MJ.Inventory.Blender
  alias MJ.Inventory.Types.Message

  @type t :: pid()


  ###
  ### Business API
  ###
  @spec put(t(), %Class{} | %Node{}) :: :ok
  def put(inventory, %Class{} = class) do
    GenServer.call(inventory, {:put, class})
  end

  def put(inventory, %Node{} = node) do
    GenServer.call(inventory, {:put, node})
  end

  def messages(inventory) do
    GenServer.call(inventory, {:messages})
  end

  @spec get(t(), {:class | :node, String.t()}) :: {:ok, %Class{} | %Node{}} | {:error, :not_found}
  @spec get(
          t(),
          {
            :class | :node,
            String.t()
          },
          :definition | :computed | :computed_all
        ) :: {:ok, %Class{} | %Node{}} | {:error, :not_found}

  @spec get(
          t(),
          {
            :class | :node,
            String.t()
          },
          :inheritance_path
        ) :: {:ok, list(String.t())} | {:error, :not_found}

  def get(inventory, {:class, _name} = obj) do
    get(inventory, obj, :definition)
  end

  def get(inventory, {:node, _name} = obj) do
    get(inventory, obj, :definition)
  end

  @spec get(t(), {:class | :node, String.t()}, :badges) :: {:ok, list(atom())} | {:error, :not_found}
  def get(inventory, {:class, _name} = obj, :badges) do
    GenServer.call(inventory, {:get, obj, :badges})
  end

  def get(inventory, {:node, _name} = obj, :badges) do
    GenServer.call(inventory, {:get, obj, :badges})
  end

  def get(inventory, {:class, _name} = obj, :definition) do
    GenServer.call(inventory, {:get, obj, :definition})
  end

  def get(inventory, {:node, _name} = obj, :definition) do
    GenServer.call(inventory, {:get, obj, :definition})
  end

  def get(inventory, {:class, _name} = obj, :computed) do
    GenServer.call(inventory, {:get, obj, :computed})
  end

  def get(inventory, {:node, _name} = obj, :computed) do
    GenServer.call(inventory, {:get, obj, :computed})
  end

  def get(inventory, {:class, _name} = obj, :computed_all) do
    GenServer.call(inventory, {:get, obj, :computed_all})
  end

  def get(inventory, {:node, _name} = obj, :computed_all) do
    GenServer.call(inventory, {:get, obj, :computed_all})
  end

  def get(inventory, {:class, _name} = obj, :inheritance_path) do
    GenServer.call(inventory, {:get, obj, :inheritance_path})
  end

  def get(inventory, {:node, _name} = obj, :inheritance_path) do
    GenServer.call(inventory, {:get, obj, :inheritance_path})
  end

  # :TODO: implement remove
  # @spec remove(registry, {:node, _name} | Node.t() | Class.t()) :: :ok

  @spec get_names(t(), :class | :node) :: list(String.t())
  def get_names(inventory, :node) do
    GenServer.call(inventory, {:names, :node})
  end

  def get_names(inventory, :class) do
    GenServer.call(inventory, {:names, :class})
  end

  @spec get_names_and_badges(t(), :class | :node) :: list(String.t())
  def get_names_and_badges(inventory, :node) do
    GenServer.call(inventory, {:names_and_badges, :node})
  end

  def get_names_and_badges(inventory, :class) do
    GenServer.call(inventory, {:names_and_badges, :class})
  end

  @spec has_errors?(t()) :: boolean
  def has_errors?(inventory) do
    GenServer.call(inventory, {:has_errors})
  end

  def unload(inventory) do
    GenServer.call(inventory, :unload)
  end

  ###
  ### OTP API
  ###
  def start_link(init_args, opts \\ []) do
    GenServer.start_link(__MODULE__, init_args, opts)
  end

  ###
  ### Callbacks
  ###
  @enforce_keys [:definition, :cache]
  defstruct [:definition, :cache, cache_valid?: false]

  @type state :: %__MODULE__{
                   definition: Registry.t(),
                   cache: Cache.t(),
                   cache_valid?: boolean()
                 }

  @impl true
  def init([]) do
    {:ok, %__MODULE__{definition: Registry.new(), cache: Cache.new()}}
  end

  @impl true
  def handle_call({:put, %Class{} = class}, _from, %__MODULE__{} = state) do
    Registry.put(state.definition, class)
    state = invalidate_cache(state)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:put, %Node{} = node}, _from, %__MODULE__{} = state) do
    Registry.put(state.definition, node)
    state = invalidate_cache(state)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:get, {:node, name}, :computed}, _from, %__MODULE__{} = state) do
    state = ensure_cache(state)
    case Cache.get(state.cache, {:node, name}) do
      nil -> {:reply, {:error, :not_found}, state}
      node -> {:reply, node, state}
    end
  end

  @impl true
  def handle_call({:get, {:node, name}, :computed_all}, _from, %__MODULE__{} = state) do
    state = ensure_cache(state)
    {:ok, node} = Registry.get(state.definition, {:node, name})
    {all, _} = compute_object(state, node)
    {:reply, all, state}
  end

  @impl true
  def handle_call({:get, {:node, name}, :inheritance_path}, _from, %__MODULE__{} = state) do
    {:ok, node} = Registry.get(state.definition, {:node, name})
    reply = Inheritance.inheritance_path(node, state.definition)
            |> Enum.drop(-1)
            |> Enum.map(fn {:class, name} -> name end)
    {:reply, reply, state}
  end

  @impl true
  def handle_call({:get, {:node, name}, :badges}, _from, %__MODULE__{} = state) do
    state = ensure_cache(state)
    case Cache.get(state.cache, {:node, name}, :badges) do
      nil -> {:reply, {:error, :not_found}, state}
      badges -> {:reply, badges, state}
    end
  end

  @impl true
  def handle_call({:get, {:node, name}, :definition}, _from, %__MODULE__{} = state) do
    node = Registry.get(state.definition, {:node, name})
    {:reply, node, state}
  end

  @impl true
  def handle_call({:get, {:class, name}, :badges}, _from, %__MODULE__{} = state) do
    state = ensure_cache(state)
    case Cache.get(state.cache, {:class, name}, :badges) do
      nil -> {:reply, {:error, :not_found}, state}
      badges -> {:reply, badges, state}
    end
  end

  @impl true
  def handle_call({:get, {:class, name}, :computed}, _from, %__MODULE__{} = state) do
    state = ensure_cache(state)
    case Cache.get(state.cache, {:class, name}) do
      nil -> {:reply, {:error, :not_found}, state}
      class -> {:reply, class, state}
    end
  end

  @impl true
  def handle_call({:get, {:class, name}, :computed_all}, _from, %__MODULE__{} = state) do
    state = ensure_cache(state)
    {:ok, class} = Cache.get(state.cache, {:class, name})
    {all, _} = compute_object(state, class)
    {:reply, all, state}
  end

  @impl true
  def handle_call({:get, {:class, name}, :inheritance_path}, _from, %__MODULE__{} = state) do
    {:ok, class} = Registry.get(state.definition, {:class, name})
    reply = Inheritance.inheritance_path(class, state.definition)
            |> Enum.drop(-1)
            |> Enum.map(fn {:class, name} -> name end)
    {:reply, reply, state}
  end

  @impl true
  def handle_call({:get, {:class, name}, :definition}, _from, %__MODULE__{} = state) do
    class = Registry.get(state.definition, {:class, name})
    {:reply, class, state}
  end

  @impl true
  def handle_call({:names, :node}, _from, %__MODULE__{} = state) do
    {:reply, Registry.get_names(state.definition, :node), state}
  end

  @impl true
  def handle_call({:names, :class}, _from, %__MODULE__{} = state) do
    {:reply, Registry.get_names(state.definition, :class), state}
  end

  @impl true
  def handle_call({:names_and_badges, :node}, _from, %__MODULE__{} = state) do
    state = if state.cache_valid? do
      state
    else
      ensure_cache(state)
    end
    {:reply, Cache.get_names_and_badges(state.cache, :node), state}
  end

  @impl true
  def handle_call({:names_and_badges, :class}, _from, %__MODULE__{} = state) do
    state = if state.cache_valid? do
      state
    else
      ensure_cache(state)
    end
    {:reply, Cache.get_names_and_badges(state.cache, :class), state}
  end

  @impl true
  def handle_call(:unload, _from, %__MODULE__{} = state) do
    Registry.remove_all(state.definition)
    state = invalidate_cache(state)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:messages}, _from, %__MODULE__{} = state) do
    state = if state.cache_valid? do
      state
    else
      ensure_cache(state)
    end
    {:reply, Cache.messages(state.cache), state}
  end

  @impl true
  def handle_call({:has_errors}, _from, %__MODULE__{} = state) do
    state = if state.cache_valid? do
      state
    else
      ensure_cache(state)
    end
    {:reply, Cache.has_errors?(state.cache), state}
  end

  ###
  ### HELPER FUNCTIONS
  ###
  def invalidate_cache(state) do
    Cache.remove_all(state.cache)
    %__MODULE__{state | cache_valid?: false}
  end

  # Make sure all classes and nodes are in the cache.
  #
  # This is needed to know if the inventory is valid (has errors).
  defp ensure_cache(state) do
    # First we cache all nodes and as a side effect cache all classes inherited by those nodes
    cache_valid =
      Registry.get_names(state.definition, :node)
      |> Enum.reduce(
           true,
           fn name, acc ->
             case ensure_cache(state, {:node, name}) do
               {_, %Node{}} ->
                 acc
               {_, %Class{}} -> throw :should_not_happen
             end
           end
         )

    # Now we cache the remaining classes. By definition all classes not cached yet are unused. We mark them accordingly.
    cache_valid =
      Registry.get_names(state.definition, :class)
      |> Enum.reduce(
           cache_valid,
           fn name, acc ->
             case Cache.get(state.cache, {:class, name}) do
               {:ok, _} ->
                 acc
               nil ->
                 # This class is unused.
                 case ensure_cache(state, {:class, name}, [:unused]) do
                   {_, %Class{}} -> acc
                   {_, %Node{}} -> throw :should_not_happen
                 end
             end
           end
         )

    %__MODULE__{state | cache_valid?: cache_valid}
  end

  @spec ensure_cache(
          state(),
          {:class, String.t()} | {:node, String.t()}
        ) :: {:ok, %Node{} | %Class{}}

  defp ensure_cache(state, what, badges \\ [])

  defp ensure_cache(state, {:node, name}, badges) do
    result = compute(state, {:node, name})
    badges = case result do
      {:ok, object} ->
        badges = if object.valid? do
          badges
        else
          [:invalid | badges]
        end
        badges = case Enum.find(object.messages, & &1.severity == :warning) do
          nil ->
            badges
          _ ->
            [:warnings | badges]
        end
        badges
    end
    Cache.put(state.cache, {:node, name}, result, badges)
    result
  end

  defp ensure_cache(state, {:class, name}, badges) do
    result = compute(state, {:class, name})
    badges = case result do
      {:ok, object} ->
        badges =
          if object.valid? do
            badges
          else
            [:invalid | badges]
          end
        badges = case Enum.find(object.messages, & &1.severity == :warning) do
          nil ->
            badges
          _ ->
            [:warnings | badges]
        end
        badges
    end
    Cache.put(state.cache, {:class, name}, result, badges)
    result
  end

  @spec compute(
          state(),
          {:class | :node, String.t()}
        ) :: {:ok, %Class{} | %Node{}}
  defp compute(state, {:class, name}) do
    case Registry.get(state.definition, {:class, name}) do
      {:ok, class} ->
        case compute_object(state, class) do
          {_, {:ok, result}} -> {:ok, result}
        end
      {:error, :not_found} ->
        {:ok, %Class{name: name, valid?: false, messages: [Message.error("error:class is not defined")]}}
    end
  end

  defp compute(state, {:node, name}) do
    {:ok, node} = Registry.get(state.definition, {:node, name})
    case compute_object(state, node) do
      {_, {:ok, result}} ->
        case MJ.Inventory.Interpolation.Reclass.interpolate(result) do
          {:error, :circular_dependency, stack} ->
            {
              :ok,
              %{
                result |
                valid?: false,
                messages: [
                  Message.error("error:interpolation failed because of circular dependency:#{stack}") | result.messages
                ]
              }
            }
          {:error, :invalid_reference, _stack, what} ->
            {
              :ok,
              %{
                result |
                valid?: false,
                messages: [
                  Message.error("interpolation failed because of invalid reference '#{what}'") | result.messages
                ]
              }
            }
          node ->
            {:ok, node}
        end
    end
  end

  @spec compute_object(
          state(),
          %Class{} | %Node{}
        ) :: {list({:ok, %Class{} | %Node{}}), {:ok, %Class{} | %Node{}}}
  defp compute_object(state, object) do
    object.classes
    |> Enum.each(fn clsname -> ensure_cache(state, {:class, clsname}) end)
    compute_chain(state, Inheritance.inheritance_path(object, state.definition))
  end

  @spec compute_chain(
          state(),
          [{:class | :node, String.t()}]
        ) :: {list({:ok, %Class{} | %Node{}}), {:ok, %Class{} | %Node{}}}
  defp compute_chain(state, inheritance_path) when is_list(inheritance_path) do
    inheritance_path
    |> Enum.map(
         fn
           parent ->
             case Registry.get(state.definition, parent) do
               {:error, :not_found} ->
                 case parent do
                   {:class, name} ->
                     {:ok, %Class{name: name, valid?: false, messages: [Message.error("error:class is not defined")]}}
                 end
               {:ok, _} = result ->
                 result
             end
         end
       )
    |> Enum.map_reduce(
         {:ok, nil},
         fn
           # This is only called once for the first base class
           {:ok, definition}, {:ok, nil} ->
             {{:ok, definition}, {:ok, definition}}
           # This is called for the complete inheritance chain if everything is ok
           {:ok, definition}, {:ok, parent} ->
             case Blender.blend(parent, definition) do
               {:ok, blended} -> {{:ok, blended}, {:ok, blended}}
             end
         end
       )
  end

end