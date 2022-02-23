defmodule Cctv.Cleaner do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl GenServer
  def init(_init_arg) do
    clean_timeout =
      "CCTV_CLEAN_INTERVAL"
      |> System.get_env("60000")
      |> String.to_integer()

    state = %{clean_timeout: clean_timeout}
    schedule_cleaning(state)
    {:ok, state}
  end

  @impl GenServer
  def handle_info(:clean, state) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.to_erl()
    recordings_dir = Cctv.Stream.recordings_dir()
    current_stream_name = Cctv.Stream.recording_name()

    most_recent_time =
      case current_stream_name do
        nil ->
          now

        stream_name ->
          stream_file = Path.join(recordings_dir, stream_name)

          if File.exists?(stream_file) do
            stream_file
            |> File.lstat!(time: :universal)
            |> then(& &1.mtime)
          else
            now
          end
      end

    sorted_recordings =
      recordings_dir
      |> File.ls!()
      |> Enum.map(&Path.join(recordings_dir, &1))
      |> Enum.map(&{&1, File.lstat!(&1, time: :universal).mtime})
      |> Enum.filter(fn {_, mtime} -> mtime < most_recent_time end)
      |> Enum.sort_by(fn {_, mtime} -> mtime end)
      |> Enum.map(fn {filename, _mtime} -> filename end)

    for file <- sorted_recordings, cleaning_needed?(recordings_dir) do
      File.rm!(file)
    end

    schedule_cleaning(state)
    {:noreply, state}
  end

  defp schedule_cleaning(state) do
    Process.send_after(self(), :clean, state.clean_timeout)
  end

  def cleaning_needed?(folder) do
    clean_threshold =
      "CCTV_CLEAN_THRESHOLD"
      |> System.get_env("90")
      |> String.to_integer()

    :disksup.get_disk_data()
    |> Enum.map(fn {mount_point, _size, percent_full} ->
      mount_point = List.to_string(mount_point)

      common_prefix_length =
        if String.starts_with?(folder, mount_point) do
          String.length(mount_point)
        else
          0
        end

      %{
        common_prefix_length: common_prefix_length,
        percent_full: percent_full
      }
    end)
    |> Enum.max_by(fn %{common_prefix_length: length} -> length end)
    |> then(&(&1.percent_full >= clean_threshold))
  end
end
