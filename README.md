# Cctv

Very simple home CCTV system.
It uses Raspberry PI to record video and stream it to YouTube.
It is work in progress.

## Requirements
- Raspberry Pi, at least 3
- df
- ffmpeg >= 4.4 (you can compile ffmpeg by yourself or use static builds [according to the docs](https://trac.ffmpeg.org/wiki/CompilationGuide/Ubuntu).
- Erlang
- Elixir

## Optional requirements
- motion sensor, like HC-SR501. You can replace it with a simple pushbutton, or emulate using `CCTV_EMULATE_MOTION_SENSOR` environment variable.

## Environment variables
- `CCTV_SERVER_NAME` - Elixir server name. It is used to connect to remote application (default "cctv").
- `CCTV_CLEAN_INTERVAL` - Time in milliseconds between cleaning recordings (default "60000")
- `CCTV_CLEAN_THRESHOLD` - Threshold in percent of disk space. System will not delete old recordings until threshold is reached (default "90").
- `CCTV_MOTION_SENSOR_PIN` - Pin number of the motion sensor input (default "17").
- `CCTV_EMULATE_MOTION_SENSOR` - Whether to emulate motion sensor. Set 1 if your hardware does not support motion sensor (default "0", or do not emulate it).
- `CCTV_VIDEO_INPUT_COMMAND` - Set a video input command. (Will use static image by default).
- `CCTV_STREAM_URL` - Set a video stream url (empty by default). Application will not stream any data if this value is empty.
- `CCTV_STREAM_END_DELAY` - Time in milliseconds to keep streaming after the motion stopped (default "60000").
- `CCTV_TELEGRAM_BOT_TOKEN` - Telegram bot token for sending notifications (empty by default).
- `CCTV_TELEGRAM_CHAT_ID` - Telegram chat id for sending notifications (empty by default). You can use [this gist](https://gist.github.com/dideler/85de4d64f66c1966788c1b2304b9caf1) to find out the chat id.
- `CCTV_TELEGRAM_STREAM_START_MESSAGE` - A message to send to telegram when the stream has started (default "Motion detected, starting a stream.").
- `CCTV_TELEGRAM_STREAM_END_MESSAGE` - A telegram message to send after stream end (default "Stream has stopped.").

## Useful commands
- `docker run --rm --name nginx-rtmp -p 1935:1935 -p 8080:80 --rm alfg/nginx-rtmp` starts nginx with rtmp support. You can stream into it by `rtmp://your_ip:1935/stream` url.
- `ffplay rtmp://localhost:1935/stream` - preview stream

## Getting started
- Install or check all the requirements
- clone the project `git clone https://github.com/RomanKotov/cctv.git`
- Install project dependencies `mix deps.get`
- Create .env file. You can use `cp .env.example .env` and adjust it.
- Run `./start.sh` to start an application.

## Options for start.sh
- `./start.sh` starts an application interactively.
- `./start.sh daemon` run application in non-interactive mode.
- `./start.sh daemon-connect` connect to a running daemonized application.

## Video input commands
- `raspivid -o - -t 0 -w 1280 -h 720 -fps 25 -g 50` - Capture video with `raspivid` util.

## Video stream urls
- `rtmp://localhost:1935/stream` - stream to the rtmp server from `Useful commands` section.

## Daemonizing application
You can run CCTV application as a daemon. To do it with systemd:
- `sudo cp priv/cctv.service.template /etc/systemd/system/cctv.service`
- adjust the file at `/etc/systemd/system/cctv.service`
- `sudo systemctl daemon reload`
- `sudo systemctl start cctv.service`
- `sudo systemctl enable cctv.service` if you want to start it on system start.
