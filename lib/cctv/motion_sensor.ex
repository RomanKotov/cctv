defmodule Cctv.MotionSensor do
  use GenServer

  @no_sensor_message """
  Unable to connect to a motion sensor.
  You can emulate it by setting `CCTV_EMULATE_MOTION_SENSOR` environment variable.
  Please refer to the Readme.
  Stopping the applicaion.
  """

  @allowed_sensor_values [0, 1]

  defstruct [:sensor_pin, :gpio]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def emulate_sensor_value(value) when value in @allowed_sensor_values do
    GenServer.call(__MODULE__, {:emulate_sensor_value, value})
  end

  @impl GenServer
  def init(_init_arg) do
    sensor_pin =
      "CCTV_MOTION_SENSOR_PIN"
      |> System.get_env("17")
      |> String.to_integer()

    {:ok, %__MODULE__{sensor_pin: sensor_pin}, {:continue, :init_sensor}}
  end

  @impl GenServer
  def handle_continue(:init_sensor, state = %__MODULE__{sensor_pin: pin}) do
    gpio =
      case Circuits.GPIO.open(pin, :input) do
        {:ok, gpio} ->
          Circuits.GPIO.set_interrupts(gpio, :both)
          gpio

        {:error, :export_failed} ->
          stop_application_if_no_sensor_support!()
          nil
      end

    {:noreply, %__MODULE__{state | gpio: gpio}}
  end

  @impl GenServer
  def handle_call({:emulate_sensor_value, value}, _from, %__MODULE__{sensor_pin: pin} = state)
      when value in @allowed_sensor_values do
    stop_application_if_no_sensor_support!()
    send(
      self(),
      {:circuits_gpio, pin, System.monotonic_time(), value}
    )

    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_info({:circuits_gpio, pin, _timestamp, value}, state = %__MODULE__{sensor_pin: pin})
      when value in @allowed_sensor_values do
    case value do
      1 -> Cctv.Recorder.start_recording()
      0 -> Cctv.Recorder.stop_recording()
    end

    {:noreply, state}
  end

  defp stop_application_if_no_sensor_support! do
    emulation_state =
      "CCTV_EMULATE_MOTION_SENSOR"
      |> System.get_env("0")
      |> String.to_integer()

    if emulation_state != 1 do
      IO.puts(@no_sensor_message)
      System.stop(1)
    end
  end
end
