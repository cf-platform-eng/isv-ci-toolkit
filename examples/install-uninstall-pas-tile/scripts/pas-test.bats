#!/usr/bin/env bats

setup() {
    export BATS_TMPDIR
    mkdir -p "$BATS_TMPDIR/bin"

    mkdir -p "$BATS_TMPDIR/om-calls"
    cat > "$BATS_TMPDIR/bin/om" <<'EOF'
#!/usr/bin/env bash
call=0
while [ -e "$BATS_TMPDIR/om-calls/${call}" ] ; do
    call=$((call+1))
done
echo -n "$@" > "$BATS_TMPDIR/om-calls/${call}"
exit ${MOCK_OM_RETURN_CODE:-0}
EOF

    echo 'exit 0' > "$BATS_TMPDIR/bin/build_tile_config.sh"
    echo 'exit 0' > "$BATS_TMPDIR/bin/upload_and_assign_stemcells.sh"

    echo 'echo ${MOCK_TILEINSPECT_OUTPUT}; exit ${MOCK_TILEINSPECT_RETURN_CODE:-0}' > "$BATS_TMPDIR/bin/tileinspect"

    chmod a+x "$BATS_TMPDIR/bin"/*
    export PATH="$BATS_TMPDIR/bin:${PATH}"
}

teardown() {
    rm -rf "$BATS_TMPDIR/bin"
    rm -rf "$BATS_TMPDIR/om-calls"
    unset MOCK_OM_RETURN_CODE
    unset MOCK_TILEINSPECT_OUTPUT
    unset MOCK_TILEINSPECT_RETURN_CODE
}

@test "happy path calls the right om calls" {
    export MOCK_TILEINSPECT_OUTPUT='{
        "name": "my-tile",
        "product_version": "1.2.3"
    }'

    export TILE_NAME=my-tile.pivotal
    export TILE_CONFIG=config.json
    run ${BATS_TEST_DIRNAME}/pas-test.sh
    [ "$status" -eq 0 ]
    [ -e "$BATS_TMPDIR/om-calls/0" ]
    [ "$(cat "$BATS_TMPDIR/om-calls/0")" = "upload-product -p /tile/my-tile.pivotal" ]
    [ -e "$BATS_TMPDIR/om-calls/1" ]
    [ "$(cat "$BATS_TMPDIR/om-calls/1")" = "stage-product --product-name my-tile --product-version 1.2.3" ]
    [ -e "$BATS_TMPDIR/om-calls/2" ]
    [ "$(cat "$BATS_TMPDIR/om-calls/2")" = "curl -s -p /api/v0/stemcell_assignments" ]
    [ -e "$BATS_TMPDIR/om-calls/3" ]
    [ "$(cat "$BATS_TMPDIR/om-calls/3")" = "configure-product --config ./config.json" ]
    [ -e "$BATS_TMPDIR/om-calls/4" ]
    [ "$(cat "$BATS_TMPDIR/om-calls/4")" = "apply-changes" ]
    [ -e "$BATS_TMPDIR/om-calls/5" ]
    [ "$(cat "$BATS_TMPDIR/om-calls/5")" = "unstage-product -p my-tile" ]
    [ -e "$BATS_TMPDIR/om-calls/6" ]
    [ "$(cat "$BATS_TMPDIR/om-calls/6")" = "apply-changes" ]
    [ -e "$BATS_TMPDIR/om-calls/7" ]
    [ "$(cat "$BATS_TMPDIR/om-calls/7")" = "delete-product -p my-tile -v 1.2.3" ]
}