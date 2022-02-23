#!/bin/bash

PROJECT_FOLDER=$(dirname $0)
cd $PROJECT_FOLDER

if [ -f .env ]
then
  export $(cat .env | sed 's/#.*//g' | xargs)
fi

MIX_ENV=prod iex --sname ${CCTV_SERVER_NAME:-cctv} -S mix
