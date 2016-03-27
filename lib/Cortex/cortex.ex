defmodule Cerebrum.Cortex do
  defstruct sensor_pids: [], neuron_pids: [], actuator_pids: []

  def start_link(exo_self) do
    Task.start_link(fn -> loop(exo_self) end)
  end

  defp loop(exo_self) do
    receive do
      {^exo_self, cortex, total_steps} ->
        for sensor <- cortex.sensor_pids, do: send sensor, {:sync}
        loop(exo_self, cortex, cortex.actuator_pids, total_steps - 1)
    end
  end

  defp loop(exo_self, cortex, _actuator_pids, 0) do
    neurons = get_backup(cortex.neuron_pids)
    send exo_self, {:backup, self(), neurons}
    terminate(cortex)
  end

  defp loop(exo_self, cortex, [first_actuator_pid|remaining_actuator_pids], step) do
    receive do
      {:sync, ^first_actuator_pid} ->
        loop(exo_self, cortex, remaining_actuator_pids, step)
      {:terminate} -> terminate(cortex)
    end
  end

  defp loop(exo_self, cortex, [], step) do
    for sensor <- cortex.sensor_pids, do: send sensor, {:sync}
    loop(exo_self, cortex, cortex.actuator_pids, step - 1)
  end

  defp terminate(pids) when is_list(pids) do
    for pid <- pids, do: send pid, {:terminate}
  end

  defp terminate(cortex) do
    terminate(cortex.sensor_pids)
    terminate(cortex.neuron_pids)
    terminate(cortex.actuator_pids)
  end

  defp get_backup(neurons), do: get_backup(neurons, [])

  defp get_backup([first_neuron_pid | remaining_neuron_pids], acc) do
    send first_neuron_pid, {:backup}
    receive do
      {:backup, ^first_neuron_pid, neuron} ->
        get_backup(remaining_neuron_pids, [neuron | acc])
    end
  end

  defp get_backup([], acc), do: acc

end