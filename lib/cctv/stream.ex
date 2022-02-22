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
      :exec.run_link(
        "#{video_input()} | #{video_output(recording_path)}",
        [{:group, 0}, :kill_group]
      )

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

    {:reply, :ok, %__MODULE__{}}
  end

  def handle_call(:recording_name, _from, %__MODULE__{recording_name: name} = state) do
    {:reply, name, state}
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

    System.get_env("CCTV_VIDEO_INPUT_COMMAND", dummy_input)
  end

  defp video_output(recording_path) do
    stream_url = System.get_env("CCTV_STREAM_URL", "rtmp://127.0.0.1:1935/stream")

    [
      "ffmpeg",
      "-hide_banner -v error",
      "-re -ar 44100 -ac 2 -acodec pcm_s16le -f s16le -ac 2 -i /dev/zero",
      "-f h264 -i -",
      "-vcodec copy -acodec aac -ab 128k -g 50 -strict experimental -bsf:v setts=ts=N -f flv",
      stream_url,
      "-c copy -f h264",
      recording_path
    ]
    |> Enum.join(" ")
  end
end
