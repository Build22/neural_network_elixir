defmodule NeuralNetwork.Network do
  alias NeuralNetwork.{Layer, Network}

  defstruct pid: "", input_layer: %{}, output_layer: %{}, hidden_layers: %{}

  def start_link(layer_sizes \\ []) do
    {:ok, pid} = Agent.start_link(fn -> %Network{} end)

    layers = %{
      input_layer:    input_neurons(layer_sizes),
      output_layer:   output_neurons(layer_sizes),
      hidden_layers:  hidden_neurons(layer_sizes)
    }

    connected_layers = layers |> connect_layers

    layers = %{
      input_layer:    List.first(connected_layers),
      hidden_layers:   hidden_layer_slice(connected_layers),
      output_layer:  List.last(connected_layers)
    }

    update(pid, layers)
  end

  def get(pid), do: Agent.get(pid, &(&1))

  def update(pid, fields) do
    Agent.update(pid, fn network -> Map.merge(network, fields) end)
    get(pid)
  end

  defp input_neurons(layer_sizes) do
    size = layer_sizes |> List.first
    Layer.start_link(%{neuron_size: size})
  end

  defp output_neurons(layer_sizes) do
    size = layer_sizes |> List.last
    Layer.start_link(%{neuron_size: size})
  end

  defp hidden_neurons(layer_sizes) do
    layer_sizes
    |> hidden_layer_slice
    |> Enum.map(fn size ->
         Layer.start_link(%{neuron_size: size})
       end)
  end

  defp hidden_layer_slice(layer_sizes) do
    layer_sizes
    |> Enum.slice(1..length(layer_sizes) - 2)
  end

  defp connect_layers(olayers) do
    layers = olayers |> flatten_layers

    layers
    |> Stream.with_index
    |> Enum.each(fn(tuple) ->
      {layer, index} = tuple
      next_index = index + 1

      if Enum.at(layers, next_index) do
        Layer.connect(layer, Enum.at(layers, next_index))
      end
    end)

    Enum.map(layers, fn layer -> Layer.get(layer.pid) end)
  end

  defp flatten_layers(layers) do
    [layers.input_layer] ++ layers.hidden_layers ++ [layers.output_layer]
  end
end