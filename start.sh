#!/bin/bash

PROJECT_FOLDER=$(dirname $0)
cd $PROJECT_FOLDER

if [ -f .env ]
then
  . .env
fi

export MIX_ENV=prod

case $1 in
  daemon-connect)
    iex --remsh ${CCTV_SERVER_NAME:-cctv} --sname client-$RANDOM
    ;;
  daemon)
   elixir --sname ${CCTV_SERVER_NAME:-cctv} -S mix run --no-halt
    ;;
  *)
    iex -S mix
    ;;
esac

MIX_ENV=prod iex --sname ${CCTV_SERVER_NAME:-cctv} -S mix
