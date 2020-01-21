#!/usr/bin/env bash

command=${1:-run}

usage() {
  echo "CN-JEB entrypoint standard"
  echo ""
  echo "Commands are:"
  echo "  help"
  echo "  run"
  echo "  shell"
  echo "  needs"
  echo "  list-needs"

}

case "${command}" in
  run)
    ./run.sh
    ;;
  *needs)
    needs list
    ;;
  shell)
    $SHELL
    ;;
  *)
    usage
    ;;
esac