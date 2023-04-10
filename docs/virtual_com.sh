#!/bin/sh

socat PTY,link=/tmp/ttyS0,raw,echo=1 PTY,link=/tmp/ttyS1,raw,echo=0 &
