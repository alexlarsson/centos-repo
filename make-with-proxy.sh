#!/bin/bash
# Ensure polipo is running at port 8123 for this to work
make PROXY="--proxy=http://127.0.0.1:8123" "$@"
