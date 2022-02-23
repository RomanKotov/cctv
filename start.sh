#!/bin/bash

PROJECT_FOLDER=$(dirname $0)
cd $PROJECT_FOLDER

if [ -f .env ]
then
  . .env
fi

MIX_ENV=prod iex --sname ${CCTV_SERVER_NAME:-cctv} -S mix
