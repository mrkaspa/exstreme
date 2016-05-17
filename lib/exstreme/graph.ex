defmodule Exstreme.Graph do
  @moduledoc """
  """
  alias __MODULE__

  @type t :: %Graph{params: [key: term], nodes: %{key: [key: term]}, connections: %{key: atom}}
  defstruct params: [], nodes: %{}, connections: %{}

  @doc """
  """
  @spec count_nodes(t) :: non_neg_integer
  def count_nodes(%Graph{nodes: nodes}) do
    nodes
    |> Map.keys
    |> Enum.count
  end

  @doc """
  """
  @spec count_connections(t) :: non_neg_integer
  def count_connections(%Graph{connections: connections}) do
    connections
    |> Map.values
    |> List.flatten
    |> Enum.count
  end

  @doc """
  """
  @spec connections_stats(t) :: %{key: integer}
  def connections_stats(graph) do
    graph
    |> map_to_connections
    |> Enum.reduce(Map.new, fn(key, map) ->
        Map.update(map, key, 1, &(&1 + 1))
      end)
  end

  @doc """
  """
  @spec find_start_node(t) :: [atom]
  def find_start_node(%Graph{nodes: nodes, connections: connections}) do
    is_first? =
      fn(node) ->
        at_first?(connections, node) and not(at_last?(connections, node))
      end

    nodes
    |> Map.keys
    |> Enum.filter(is_first?)
  end

  @spec get_before_nodes(t, atom) :: [atom]
  def get_before_nodes(%Graph{connections: connections}, node) do
    compare_func =
      fn(current_node, {_from, to}) ->
        current_node == to
      end
    Enum.reduce(connections, [], fn(connection, res) ->
      res ++ get_nodes_func(node, connection, res, compare_func)
    end)
  end

  @spec get_after_nodes(t, atom) :: [atom]
  def get_after_nodes(%Graph{nodes: nodes, connections: connections}, node) do
    compare_func =
      fn(current_node, {from, _to}) ->
        current_node == from
      end
    Enum.reduce(connections, [], fn(connection, res) ->
      res ++ get_nodes_func(node, connection, res, compare_func)
    end)
  end

  # private

  @spec map_to_connections(t) :: [atom]
  defp map_to_connections(%Graph{nodes: nodes, connections: connections}) do
    to_connections =
      fn(node) ->
        case {at_first?(connections, node), at_last?(connections, node)} do
          {true, true}   -> :connected
          {true, false}  -> :begin
          {false, true}  -> :end
          {false, false} -> :unconnected
        end
      end

    nodes
    |> Map.keys
    |> Enum.map(to_connections)
  end

  @spec at_first?(%{key: atom}, atom) :: boolean
  defp at_first?(connections,  node) do
    Map.has_key?(connections, node)
  end

  @spec at_last?(%{key: atom}, atom) :: boolean
  defp at_last?(connections,  node) do
    connections
    |> Map.values
    |> List.flatten
    |> Enum.member?(node)
  end

  @spec get_nodes_func(atom, {atom, atom}, [atom], ((atom, {atom, atom}) -> boolean)) :: [atom]
  defp get_nodes_func(node, pair = {from, to}, res, func) do
    case to do
      to when is_atom(to) ->
        if func.(node, pair) do
          [res | node]
        else
          res
        end
      to when is_list(to) ->
        Enum.map(to, fn(current_to) ->
          get_nodes_func(node, {from, current_to}, res, func)
        end)
    end
  end
end
