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

## Environment variables
- `CCTV_CLEAN_INTERVAL` - Time in milliseconds between cleaning recordings (default "60000")
- `CCTV_CLEAN_THRESHOLD` - Threshold in percent of disk space. System will not delete old recordings until threshold is reached (default "90").

## Useful commands
- `docker run --rm --name nginx-rtmp -p 1935:1935 -p 8080:80 --rm alfg/nginx-rtmp` starts nginx with rtmp support. You can stream into it by `rtmp://your_ip:1935/stream` url.
- `ffplay rtmp://localhost:1935/stream` - preview stream
