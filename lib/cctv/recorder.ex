defmodule Cctv.Recorder do
  use GenServer

  defstruct [:stream_end_timer]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def start_recording do
    GenServer.call(__MODULE__, :start_recording)
  end

  def stop_recording do
    GenServer.call(__MODULE__, :stop_recording)
  end

  @impl GenServer
  def init(_init_arg) do
    {:ok, %__MODULE__{}}
  end

  @impl GenServer
  def handle_call(:start_recording, _from, state) do
    cancel_timer(state)
    {:reply, Cctv.Stream.start_streaming(), state}
  end

  @impl GenServer
  def handle_call(:stop_recording, _from, state) do
    cancel_timer(state)

    stream_end_delay =
      "CCTV_STREAM_END_DELAY"
      |> System.get_env("60000")
      |> String.to_integer()

    timer = Process.send_after(__MODULE__, :stop_streaming, stream_end_delay)
    {:reply, :ok, %__MODULE__{stream_end_timer: timer}}
  end

  @impl GenServer
  def handle_info(:stop_streaming, _state) do
    Cctv.Stream.stop_streaming()
    {:noreply, %__MODULE__{}}
  end

  defp cancel_timer(%__MODULE__{stream_end_timer: timer}) do
    case timer do
      nil -> :ok
      timer -> Process.cancel_timer(timer)
    end
  end
end
