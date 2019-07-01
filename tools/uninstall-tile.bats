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
    run ./uninstall-tile.sh
    [ "$status" -eq 1 ]
    [ "$output" = "usage: uninstall-tile.sh <tile>" ]
}

@test "exits if om unstage-product fails" {
    export OM_FAIL_COMMAND=unstage-product
    export MOCK_TILEINSPECT_OUTPUT='{
        "name": "my-tile",
        "product_version": "1.2.3"
    }'        
    run ./uninstall-tile.sh tile.pivotal
    [ "$status" -eq 1 ]
    [ "$output" = "Failed to unstage product my-tile" ]
}

@test "exits if om apply-changes fails" {
    export OM_FAIL_COMMAND=apply-changes
    run ./uninstall-tile.sh tile.pivotal
    [ "$status" -eq 1 ]
    [ "$output" = "Failed to apply changes" ]
}

@test "exits if om delete-product fails" {
    export OM_FAIL_COMMAND=delete-product
    export MOCK_TILEINSPECT_OUTPUT='{
        "name": "my-tile",
        "product_version": "1.2.3"
    }'        
    run ./uninstall-tile.sh tile.pivotal
    [ "$status" -eq 1 ]
    [ "$output" = "Failed to delete version 1.2.3 of my-tile" ]
}

