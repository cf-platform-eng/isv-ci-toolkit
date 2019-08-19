#!/usr/bin/env bats

setup() {
    export BATS_TMPDIR
    mkdir -p "$BATS_TMPDIR/bin"

    mkdir -p "$BATS_TMPDIR/install-tile-calls"
    mkdir -p "$BATS_TMPDIR/uninstall-tile-calls"
    mkdir -p "$BATS_TMPDIR/log-dependencies-calls"
    cat > "$BATS_TMPDIR/bin/install-tile.sh" <<'EOF'
#!/usr/bin/env bash
call=0
while [ -e "$BATS_TMPDIR/install-tile-calls/${call}" ] ; do
    call=$((call+1))
done
echo -n "$@" > "$BATS_TMPDIR/install-tile-calls/${call}"
exit ${MOCK_INSTALL_TILE_RETURN_CODE:-0}
EOF

    cat > "$BATS_TMPDIR/bin/uninstall-tile.sh" <<'EOF'
#!/usr/bin/env bash
call=0
while [ -e "$BATS_TMPDIR/uninstall-tile-calls/${call}" ] ; do
    call=$((call+1))
done
echo -n "$@" > "$BATS_TMPDIR/uninstall-tile-calls/${call}"
exit ${MOCK_UNINSTALL_TILE_RETURN_CODE:-0}
EOF

    cat > "$BATS_TMPDIR/bin/log-dependencies.sh" <<'EOF'
#!/usr/bin/env bash
call=0
while [ -e "$BATS_TMPDIR/log-dependencies-calls/${call}" ] ; do
    call=$((call+1))
done
echo -n "$@" > "$BATS_TMPDIR/log-dependencies-calls/${call}"
EOF

    echo 'exit 0' > "$BATS_TMPDIR/bin/mrlog"
    echo 'echo ${MOCK_NEEDS_OUTPUT}; exit ${MOCK_NEEDS_RETURN_CODE:-0}' > "$BATS_TMPDIR/bin/needs"

    chmod a+x "$BATS_TMPDIR/bin"/*
    export PATH="$BATS_TMPDIR/bin:${PATH}"
}

teardown() {
    rm -rf "$BATS_TMPDIR/bin"
    rm -rf "$BATS_TMPDIR/install-tile-calls"
    rm -rf "$BATS_TMPDIR/uninstall-tile-calls"
    rm -rf "$BATS_TMPDIR/log-dependencies-calls"

    unset MOCK_NEEDS_OUTPUT
    unset MOCK_NEEDS_RETURN_CODE
    unset MOCK_INSTALL_TILE_RETURN_CODE
    unset MOCK_UNINSTALL_TILE_RETURN_CODE
}

@test "happy path calls all steps" {
    export TILE_NAME=test-tile.pivotal
    export TILE_CONFIG=test-tile.yml
    unset USE_FULL_DEPLOY
    run ${BATS_TEST_DIRNAME}/run.sh
    [ "$status" -eq 0 ]
    [ -e "$BATS_TMPDIR/log-dependencies-calls/0" ]
    [ -e "$BATS_TMPDIR/install-tile-calls/0" ]
    [ "$(cat "$BATS_TMPDIR/install-tile-calls/0")" = "/tile/test-tile.pivotal /tile-config/test-tile.yml false" ]
    [ -e "$BATS_TMPDIR/uninstall-tile-calls/0" ]
    [ "$(cat "$BATS_TMPDIR/uninstall-tile-calls/0")" = "/tile/test-tile.pivotal false" ]
}

@test "setting USE_FULL_DEPLOY passes that along to the script" {
    export TILE_NAME=test-tile.pivotal
    export TILE_CONFIG=test-tile.yml
    export USE_FULL_DEPLOY=true
    run ${BATS_TEST_DIRNAME}/run.sh
    [ "$status" -eq 0 ]
    [ -e "$BATS_TMPDIR/install-tile-calls/0" ]
    [ "$(cat "$BATS_TMPDIR/install-tile-calls/0")" = "/tile/test-tile.pivotal /tile-config/test-tile.yml true" ]
    [ -e "$BATS_TMPDIR/uninstall-tile-calls/0" ]
    [ "$(cat "$BATS_TMPDIR/uninstall-tile-calls/0")" = "/tile/test-tile.pivotal true" ]
}

@test "test exits before installing if needs are not met" {
    export MOCK_NEEDS_RETURN_CODE=1
    run ${BATS_TEST_DIRNAME}/run.sh
    [ "$status" -eq 1 ]
    [ -z "$(ls -A $BATS_TMPDIR/install-tile-calls/0)" ]
    [ -z "$(ls -A $BATS_TMPDIR/uninstall-tile-calls/0)" ]
    [ "${lines[0]}" = "needs check failed" ]
}

@test "returns error code when install tile fails" {
    export MOCK_INSTALL_TILE_RETURN_CODE=1
    run ${BATS_TEST_DIRNAME}/run.sh
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = "install-tile failed" ]
}

@test "returns error code when uninstall tile fails" {
    export MOCK_UNINSTALL_TILE_RETURN_CODE=1
    run ${BATS_TEST_DIRNAME}/run.sh
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = "uninstall-tile failed" ]
}
