# Cctv

Very simple home CCTV system.
It uses Raspberry PI to record video and stream it to YouTube.
It is work in progress.

## Requirements
- Raspberry Pi, at least 3
- df
- ffmpeg
- Erlang
- Elixir

## Optional requirements
- motion sensor, like HC-SR501. You can replace it with a simple pushbutton, or emulate using `CCTV_EMULATE_MOTION_SENSOR` environment variable.

## Environment variables
- `CCTV_CLEAN_INTERVAL` - Time in milliseconds between cleaning recordings (default "60000")
- `CCTV_CLEAN_THRESHOLD` - Threshold in percent of disk space. System will not delete old recordings until threshold is reached (default "90").
- `CCTV_STREAM_END_DELAY` - Time in milliseconds to keep streaming after the motion stopped (default "60000").
- `CCTV_MOTION_SENSOR_PIN` - Pin number of the motion sensor input (default "17").
- `CCTV_EMULATE_MOTION_SENSOR` - Whether to emulate motion sensor. Set 1 if your hardware does not support motion sensor (default "0", or do not emulate it).

## Useful commands
- `docker run --rm --name nginx-rtmp -p 1935:1935 -p 8080:80 --rm alfg/nginx-rtmp` starts nginx with rtmp support. You can stream into it by `rtmp://your_ip:1935/stream` url.
- `ffplay rtmp://localhost:1935/stream` - preview stream

## Getting started
- Install or check all the requirements
- clone the project `git clone https://github.com/RomanKotov/cctv.git`
- Install project dependencies `mix deps.get`
- Start the project `iex -S mix`. You can use `CCTV_EMULATE_MOTION_SENSOR=1 iex -S mix` if you want to test everything without motion sensor.
