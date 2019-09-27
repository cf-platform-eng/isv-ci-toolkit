#!/usr/bin/env bash

source ./steps.sh
if ! needs_check            ; then exit 1 ; fi
if ! config_file_check      ; then exit 1 ; fi
if ! log_dependencies       ; then exit 1 ; fi
if ! install_tile           ; then exit 1 ; fi
if ! uninstall_tile         ; then exit 1 ; fi
