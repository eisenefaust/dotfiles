#!/usr/bin/env bash

# not intended to be run as is. may need sudo for apptainer and /tmp clean

# clean up vscode
## remote ssh cache clean (close vscode remote connection first)
rm -rf ~/.vscode-server/data/CachedExtensionVSIXs/*
rm -f ~/.vscode-server/.cli.*.log
rm -rf ~/.vscode-server/cli/servers/Stable-*
rm -f ~/.vscode-server/code-*
rm -rf ~/.vscode-server/extensions/*.vsctmp

# clean up apptainer cache
## Dry-run to check what cache files exist
apptainer cache clean --dry-run

## Force clean all cached build layers
apptainer cache clean --force

# clean up old files in /tmp
## list total size of /tmp that would be cleaned up in MB or GB
find /tmp -mindepth 1 -mtime +3 -type f -print0 | du --files0-from=- -c -k | tail -n1 | awk '{print $1/1024 " MB"}'
## Remove regular files older than 3 days
find /tmp -mindepth 1 -type f -mtime +3 -delete

## Remove empty directories older than 3 days
find /tmp -mindepth 1 -type d -empty -mtime +3 -delete