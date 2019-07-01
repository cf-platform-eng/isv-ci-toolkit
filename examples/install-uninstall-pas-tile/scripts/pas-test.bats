#!/usr/bin/env bats

setup() {
    export BATS_TMPDIR
    mkdir -p "$BATS_TMPDIR/bin"

    mkdir -p "$BATS_TMPDIR/install-tile-calls"
    mkdir -p "$BATS_TMPDIR/uninstall-tile-calls"
    cat > "$BATS_TMPDIR/bin/install-tile.sh" <<'EOF'
#!/usr/bin/env bash
call=0
while [ -e "$BATS_TMPDIR/install-tile-calls/${call}" ] ; do
    call=$((call+1))
done
echo -n "$@" > "$BATS_TMPDIR/install-tile-calls/${call}"
EOF

    cat > "$BATS_TMPDIR/bin/uninstall-tile.sh" <<'EOF'
#!/usr/bin/env bash
call=0
while [ -e "$BATS_TMPDIR/uninstall-tile-calls/${call}" ] ; do
    call=$((call+1))
done
echo -n "$@" > "$BATS_TMPDIR/uninstall-tile-calls/${call}"
EOF

    chmod a+x "$BATS_TMPDIR/bin"/*
    export PATH="$BATS_TMPDIR/bin:${PATH}"
}

# teardown() {
#     rm -rf "$BATS_TMPDIR/bin"
#     rm -rf "$BATS_TMPDIR/install-tile-calls"
#     rm -rf "$BATS_TMPDIR/uninstall-tile-calls"
# }

@test "happy path calls install and uninstall" {
    export TILE_NAME=test-tile.pivotal
    export TILE_CONFIG=test-tile.yml
    run ${BATS_TEST_DIRNAME}/pas-test.sh
    [ "$status" -eq 0 ]
    [ -e "$BATS_TMPDIR/install-tile-calls/0" ]
    [ "$(cat "$BATS_TMPDIR/install-tile-calls/0")" = "/tile/test-tile.pivotal /tile-config/test-tile.yml" ]
    [ -e "$BATS_TMPDIR/uninstall-tile-calls/0" ]
    [ "$(cat "$BATS_TMPDIR/uninstall-tile-calls/0")" = "/tile/test-tile.pivotal" ]
}