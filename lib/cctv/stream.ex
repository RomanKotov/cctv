defmodule Cctv.Stream do
  use GenServer

  defstruct [:recording_name, :recording_pid]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def start_streaming do
    GenServer.call(__MODULE__, :start_streaming)
  end

  def stop_streaming do
    GenServer.call(__MODULE__, :stop_streaming)
  end

  @impl GenServer
  def init(_init_arg) do
    {:ok, %__MODULE__{}}
  end

  @impl GenServer
  def handle_call(:start_streaming, _from, %__MODULE__{recording_pid: nil}) do
    recording_name = generate_recording_name()
    recording_path = Path.join(recordings_dir(), recording_name)

    {:ok, recording_pid, _group_pid} =
      [
        "cat /dev/urandom |",
        "hexdump |",
        "grep 0000 >",
        recording_path
      ]
      |> Enum.join(" ")
      |> :exec.run_link([{:group, 0}, :kill_group])

    {:reply, :ok,
     %__MODULE__{
       recording_name: recording_name,
       recording_pid: recording_pid
     }}
  end

  @impl GenServer
  def handle_call(:start_streaming, _from, state), do: {:reply, :ok, state}

  @impl GenServer
  def handle_call(:stop_streaming, _from, %__MODULE__{recording_pid: nil} = state),
    do: {:reply, :ok, state}

  @impl GenServer
  def handle_call(:stop_streaming, _from, %__MODULE__{recording_pid: recording_pid}) do
    :ok = :exec.kill(recording_pid, :sigkill)

    {:reply, :ok, %__MODULE__{}}
  end

  def recordings_dir do
    [:code.priv_dir(:cctv), "recordings"]
    |> Path.join()
    |> tap(&File.mkdir_p!/1)
  end

  defp generate_recording_name do
    :calendar.local_time()
    |> NaiveDateTime.from_erl!()
    |> Calendar.strftime("%Y%m%d-%H%M%S.mp4")
  end
end
