#!/usr/bin/env bash

source ./steps.sh
if ! needs_check        ; then exit 1 ; fi
if ! configure_director ; then exit 1 ; fi
if ! download_srt       ; then exit 1 ; fi
if ! upload_srt         ; then exit 1 ; fi
if ! configure_srt      ; then exit 1 ; fi
