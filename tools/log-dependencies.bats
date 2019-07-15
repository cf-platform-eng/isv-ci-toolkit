#!/usr/bin/env bats

setup() {
    mkdir -p "$BATS_TMPDIR/home"
    export OLDHOME="${HOME}"
    export HOME="${BATS_TMPDIR}/home"
}

teardown() {
    rm -rf "$BATS_TMPDIR/home"
    export HOME=${OLDHOME}
}

@test "publishes the base image dependency logs" {
    echo "dependencies log" > "${HOME}/base-image-dependencies.log"
    run ./log-dependencies.sh
    [ "$status" -eq 0 ]
    [ "$output" = "dependencies log" ]
}

@test "missing file causes an error" {
    run ./log-dependencies.sh
    [ "$status" -eq 1 ]
}
