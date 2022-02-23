#!/bin/bash

PROJECT_FOLDER=$(dirname $0)
cd $PROJECT_FOLDER

if [ -f .env ]
then
  . .env
fi

iex --remsh ${CCTV_SERVER_NAME:-cctv} --sname client-$RANDOM
