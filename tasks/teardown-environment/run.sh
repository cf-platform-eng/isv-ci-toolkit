#!/usr/bin/env bash

source ./steps.sh
if ! needs_check          ; then exit 1 ; fi
if ! teardown_environment ; then exit 1 ; fi
