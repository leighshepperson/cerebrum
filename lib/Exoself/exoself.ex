defmodule Cerebrum.Exoself do
  alias Neo4j.Sips.Utils
  alias Cerebrum.Neuron
  alias Cerebrum.Sensor
  alias Cerebrum.Actuator
  alias Neo4j.Sips, as: Neo4j

  def get(graphName) do
  {_, result } =

    Neo4j.query(Neo4j.conn,
      "
        MATCH (c {#{graphName}: true})
        WITH collect(c) as cs
        MATCH (x)-[r]->(y)
        WHERE y in cs
        RETURN x, r, y
      ")

      result |> Enum.map(&string_to_atom_map(&1)) |> load_network
  end

  defp string_to_atom_map(%{"x" => x, "y" => y, "r" => r}) do
     %{x: string_to_atom_map(x), y: string_to_atom_map(y), r: string_to_atom_map(r)}
  end

  defp string_to_atom_map(string_map) do
    for {key, val} <- string_map, into: %{}, do: {String.to_atom(key), val}
  end

  def load_network(inputs) do
    :ets.new(:pid_id_bucket, [:named_table])
    :ets.new(:element_id_bucket, [:named_table])
    cortex_pid = self
    for input <- inputs, do: insert(input, cortex_pid)
  end

  defp lookup(bucket, key) when is_atom(bucket) do
    case :ets.lookup(bucket, key) do
      [{^key, element}] -> {:ok, element}
      [] -> :error
    end
  end

  defp get_element(%{id: id} = data, struct_type) do
    case lookup(:element_id_bucket, id) do
      {:ok, element} -> element
      :error -> struct(struct_type, data)
    end
  end

  defp get_pid(%{id: id}, struct_type, cortex_pid) do
    case lookup(:pid_id_bucket, id) do
      {:ok, pid} -> pid
      :error -> {_, pid} = apply(struct_type, :start_link, [cortex_pid])
        pid
    end
  end

  defp get_element_pid(data, struct_type, cortex_pid) do
    {get_element(data, struct_type), get_pid(data, struct_type, cortex_pid)}
  end

  defp insert_element_pid({element, pid}) do
    :ets.insert(:element_id_bucket, {element.id, element})
    :ets.insert(:pid_id_bucket, {element.id, pid})
  end

  defp insert(%{x: %{type: "sensor"} = sensor_data, y: %{type: "neuron"} = neuron_data, r: %{weights: weights}}, cortex_pid) do
    {sensor, sensor_pid} = get_element_pid(sensor_data, Cerebrum.Sensor, cortex_pid)
    {neuron, neuron_pid} = get_element_pid(neuron_data, Cerebrum.Neuron, cortex_pid)

    sensor
      |> append_output(neuron_pid)
      |> insert_element_pid

    neuron
      |> append_input(sensor_pid, weights)
      |> insert_element_pid
  end

  defp insert(%{x: %{type: "neuron"} = neuron_x_data, y: %{type: "neuron"} = neuron_y_data, r: %{weights: weights}}, cortex_pid) do
    {neuron_x, neuron_x_pid} = get_element_pid(neuron_x_data, Cerebrum.Neuron, cortex_pid)
    {neuron_y, neuron_y_pid} = get_element_pid(neuron_y_data, Cerebrum.Neuron, cortex_pid)

    neuron_x
      |> append_output(neuron_y_pid)
      |> insert_element_pid

    neuron_y
      |> append_input(neuron_x_pid, weights)
      |> insert_element_pid
  end

  defp insert(%{x: %{type: "neuron"} = neuron_data, y: %{type: "actuator"} = actuator_data}, cortex_pid) do
    {neuron, neuron_pid} = get_element_pid(neuron_data, Cerebrum.Neuron, cortex_pid)
    {actuator, actuator_pid} = get_element_pid(actuator_data, Cerebrum.Actuator, cortex_pid)

    neuron
      |> append_output(actuator_pid)
      |> insert_element_pid

    actuator
      |> append_input(neuron_pid)
      |> insert_element_pid
  end

  defp append_input(neural_element,  pid, weights) do
    {%{neural_element | inputs: Map.put_new(neural_element.inputs, pid, weights)}, pid}
  end

  defp append_input(neural_element,  pid) do
    {%{neural_element | inputs: [pid | neural_element.inputs]}, pid}
  end

  defp append_output(neural_element, pid) do
    {%{neural_element | outputs: [pid | neural_element.outputs]}, pid}
  end

end