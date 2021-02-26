#!/bin/bash

source ./steps.sh
if ! show_image_dependencies    ; then exit 1; fi
if ! check_needs                ; then exit 1; fi
setup_om
if ! enable_apps_manager_errand ; then exit 1; fi
if ! show_admin_credentials     ; then exit 1; fi
