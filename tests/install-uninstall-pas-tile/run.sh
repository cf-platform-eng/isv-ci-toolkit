#!/usr/bin/env bash

source ./steps.sh
if ! show_image_dependencies  ; then exit 1; fi
if ! check_needs              ; then exit 1; fi
if ! print_config_file        ; then exit 1; fi
if ! check_config_file        ; then exit 1; fi
if ! install_tile             ; then exit 1; fi
if ! uninstall_tile           ; then exit 1; fi

echo "tile install/uninstall finished"
