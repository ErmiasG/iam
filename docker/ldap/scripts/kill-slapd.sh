#!/bin/bash

SLAPD_PID=$(pgrep -x slapd)
if [[ $SLAPD_PID ]]; then
  kill $SLAPD_PID
fi
sleep 2