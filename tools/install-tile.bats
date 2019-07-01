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

if [ "${OM_FAIL_COMMAND}" = "$1" ]; then
    exit 1
fi

exit ${MOCK_OM_RETURN_CODE:-0}
EOF

    echo 'exit 0' > "$BATS_TMPDIR/bin/build-tile-config.sh"
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

@test "displays usage when no parameters provided" {
    run ./install-tile.sh
    [ "$status" -eq 1 ]
    [ "$output" = "usage: install-tile.sh <tile> <config.yml>" ]
}

@test "displays usage when only one parameter provided" {
    run ./install-tile.sh tile.pivotal
    [ "$status" -eq 1 ]
    [ "$output" = "usage: install-tile.sh <tile> <config.yml>" ]
}

@test "exits if om upload-product fails" {
    export OM_FAIL_COMMAND=upload-product
    run ./install-tile.sh tile.pivotal config.yml
    [ "$status" -eq 1 ]
    [ "$output" = "Failed to upload product tile.pivotal" ]
}

@test "exits if om stage-product fails" {
    export OM_FAIL_COMMAND=stage-product
    export MOCK_TILEINSPECT_OUTPUT='{
        "name": "my-tile",
        "product_version": "1.2.3"
    }'    
    run ./install-tile.sh tile.pivotal config.yml
    [ "$status" -eq 1 ]
    [ "$output" = "Failed to stage version 1.2.3 of my-tile" ]
}

@test "exits if om configure-product fails" {
    export OM_FAIL_COMMAND=configure-product
    export MOCK_TILEINSPECT_OUTPUT='{
        "name": "my-tile",
        "product_version": "1.2.3"
    }'    
    run ./install-tile.sh tile.pivotal config.yml
    [ "$status" -eq 1 ]
    [ "$output" = "Failed to configure product my-tile" ]
}

@test "exits if om apply-changes fails" {
    export OM_FAIL_COMMAND=apply-changes
    run ./install-tile.sh tile.pivotal config.yml
    [ "$status" -eq 1 ]
    [ "$output" = "Failed to apply changes" ]
}

@test "happy path calls the right om calls" {
    export MOCK_TILEINSPECT_OUTPUT='{
        "name": "my-tile",
        "product_version": "1.2.3"
    }'

    run ./install-tile.sh ./my-tile.pivotal ./config.json
    [ "$status" -eq 0 ]
    [ -e "$BATS_TMPDIR/om-calls/0" ]
    [ "$(cat "$BATS_TMPDIR/om-calls/0")" = "upload-product -p ./my-tile.pivotal" ]
    [ -e "$BATS_TMPDIR/om-calls/1" ]
    [ "$(cat "$BATS_TMPDIR/om-calls/1")" = "stage-product --product-name my-tile --product-version 1.2.3" ]
    [ -e "$BATS_TMPDIR/om-calls/2" ]
    [ "$(cat "$BATS_TMPDIR/om-calls/2")" = "curl -s -p /api/v0/stemcell_assignments" ]
    [ -e "$BATS_TMPDIR/om-calls/3" ]
    [ "$(cat "$BATS_TMPDIR/om-calls/3")" = "configure-product --config ./config.json" ]
    [ -e "$BATS_TMPDIR/om-calls/4" ]
    [ "$(cat "$BATS_TMPDIR/om-calls/4")" = "apply-changes" ]
}