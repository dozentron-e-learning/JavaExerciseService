#!/usr/bin/env sh

if [ -f tmp/pids/server.pid ]; then
  rm tmp/pids/server.pid
fi

rails s -b 0.0.0.0
