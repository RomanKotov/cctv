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

  def recording_name do
    GenServer.call(__MODULE__, :recording_name)
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
      :exec.run(
        "#{video_input()} | #{video_output(recording_path)}",
        [{:group, 0}, :kill_group, :stderr, :stdout, :monitor]
      )


    "CCTV_TELEGRAM_STREAM_START_MESSAGE"
    |> System.get_env("Motion detected, starting a stream.")
    |> Cctv.Telegram.send_message()

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
    :ok = :exec.stop(recording_pid)

    "CCTV_TELEGRAM_STREAM_END_MESSAGE"
    |> System.get_env("Stream has stopped.")
    |> Cctv.Telegram.send_message()

    {:reply, :ok, %__MODULE__{}}
  end

  @impl GenServer
  def handle_call(:recording_name, _from, %__MODULE__{recording_name: name} = state) do
    {:reply, name, state}
  end

  @impl GenServer
  def handle_info({stream, _os_pid, data}, state) when stream in [:stdout, :stderr] do
    Cctv.Telegram.send_message(
      "Got a message about stream [#{inspect(stream)}]: #{inspect(data)}"
    )
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:DOWN, _os_pid, :process, _pid, _exit_status}, _state) do
    {:noreply, %__MODULE__{}}
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

  defp video_input do
    dummy_input =
      [
        "ffmpeg",
        "-hide_banner -v error",
        "-f lavfi -i testsrc=size=1280x720:rate=25",
        "-vcodec libx264 -x264-params keyint=50 -f h264 -"
      ]
      |> Enum.join(" ")

    video_input_command = System.get_env("CCTV_VIDEO_INPUT_COMMAND", "")
    command_is_empty = String.trim(video_input_command) == ""

    if command_is_empty do
      dummy_input
    else
      video_input_command
    end
  end

  defp video_output(recording_path) do
    [
      "ffmpeg",
      "-hide_banner -v error",
      "-re -ar 44100 -ac 2 -acodec pcm_s16le -f s16le -ac 2 -i /dev/zero",
      "-f h264 -i -",
      "-c copy -f h264",
      recording_path,
      stream_params()
    ]
    |> Enum.join(" ")
  end

  def stream_params do
    stream_url = System.get_env("CCTV_STREAM_URL", "")

    empty_stream_url = String.trim(stream_url) == ""

    if empty_stream_url do
      ""
    else
      Enum.join(
        [
          "-vcodec copy -acodec aac -ab 128k -g 50 -strict experimental -bsf:v setts=ts=N -f flv",
          stream_url
        ],
        " "
      )
    end
  end
end
