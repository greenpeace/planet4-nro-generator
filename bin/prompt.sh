#!/usr/bin/env bash

read -n 1 -rp "${1:-"Does this look good?"} [y/N] " yn
case "$yn" in
    [Yy]* ) : ;;
    * ) exit 1;;
esac
