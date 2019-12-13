#!/usr/bin/env bash

#export KUBECONFIG=/input/kubeconfig

source ./steps.sh

if ! log_dependencies         ; then exit 1 ; fi
if ! needs_check              ; then exit 1 ; fi
if ! install_leftovers        ; then exit 1 ; fi
if ! prepare_chart_storage    ; then exit 1 ; fi
#if ! generate_config_file     ; then exit 1 ; fi
#if ! config_file_check        ; then exit 1 ; fi
#if ! apply_tile_config        ; then exit 1 ; fi
#if ! install_tile             ; then exit 1 ; fi
