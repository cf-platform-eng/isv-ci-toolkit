load temp/bats-mock # docs at https://github.com/grayhemp/bats-mock

setup() {
    export BATS_TMPDIR
    echo ${BATS_TMPDIR}
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

    export mock_build_tile_config="$(mock_create)"
    ln -sf "${mock_build_tile_config}" "${BATS_TMPDIR}/bin/build-tile-config.sh"

    export mock_upload_and_assign_stemcells="$(mock_create)"
    ln -sf "${mock_upload_and_assign_stemcells}" "${BATS_TMPDIR}/bin/upload_and_assign_stemcells.sh"

    export mock_tileinspect="$(mock_create)"
    ln -sf "${mock_tileinspect}" "${BATS_TMPDIR}/bin/tileinspect"

    chmod a+x "$BATS_TMPDIR/bin"/*
    export PATH="$BATS_TMPDIR/bin:${PATH}"
}

teardown() {
    rm -rf "$BATS_TMPDIR/bin"
    rm -rf "$BATS_TMPDIR/om-calls"
    unset MOCK_OM_RETURN_CODE
}

@test "displays usage when no parameters provided" {
    run ./install-tile.sh
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = "usage: install-tile.sh <tile> <config.yml> [<selective deploy>]" ]
    [ "${lines[1]}" = "    tile - path to a .pivotal file" ]
    [ "${lines[2]}" = "    config.yml - path to tile configuration" ]
    [ "${lines[3]}" = "    selective deploy - if true, only deploy this tile (default false)" ]
}

@test "displays usage when only one parameter provided" {
    run ./install-tile.sh tile.pivotal
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = "usage: install-tile.sh <tile> <config.yml> [<selective deploy>]" ]
    [ "${lines[1]}" = "    tile - path to a .pivotal file" ]
    [ "${lines[2]}" = "    config.yml - path to tile configuration" ]
    [ "${lines[3]}" = "    selective deploy - if true, only deploy this tile (default false)" ]
}

@test "exits if om upload-product fails" {
    export OM_FAIL_COMMAND=upload-product
    run ./install-tile.sh tile.pivotal config.yml
    [ "$status" -eq 1 ]
    [[ "$output" = *"Failed to upload product tile.pivotal"* ]]
    [[ "$output" = *"If you see an 'x509' error, try setting OM_SKIP_SSL_VALIDATION=true"* ]]
}

@test "exits if om stage-product fails" {
    export OM_FAIL_COMMAND=stage-product

    run ./install-tile.sh tile.pivotal config.yml
    [ "$status" -eq 1 ]
    [[ "$output" = *"Failed to stage version 1.2.3 of my-tile"* ]]
    [[ "$output" = *"If you see an 'x509' error, try setting OM_SKIP_SSL_VALIDATION=true"* ]]
}

@test "exits if om configure-product fails" {
    export OM_FAIL_COMMAND=configure-product
        ${mock_set_output} "${mock_tileinspect}" '{
            "name": "my-tile",
            "product_version": "1.2.3"
        }'

    run ./install-tile.sh tile.pivotal config.yml
    [ "$status" -eq 1 ]
    [[ "$output" = *"Failed to configure product my-tile"* ]]
    [[ "$output" = *"If you see an 'x509' error, try setting OM_SKIP_SSL_VALIDATION=true"* ]]
}

@test "exits if om apply-changes fails" {
    export OM_FAIL_COMMAND=apply-changes
    run ./install-tile.sh tile.pivotal config.yml
    [ "$status" -eq 1 ]
    [[ "$output" = *"Failed to apply changes"* ]]
    [[ "$output" = *"If you see an 'x509' error, try setting OM_SKIP_SSL_VALIDATION=true"* ]]
}

@test "happy path calls the right om calls" {
    mock_set_output "${mock_tileinspect}" '{
            "name": "my-tile",
            "product_version": "1.2.3"
        }'

    run ./install-tile.sh ./my-tile.pivotal ./config.json
    [ "$status" -eq 0 ]
    [ -e "$BATS_TMPDIR/om-calls/0" ]
    [ "$(cat "$BATS_TMPDIR/om-calls/0")" = "upload-product --product ./my-tile.pivotal" ]
    [ -e "$BATS_TMPDIR/om-calls/1" ]
    [ "$(cat "$BATS_TMPDIR/om-calls/1")" = "stage-product --product-name my-tile --product-version 1.2.3" ]
    [ -e "$BATS_TMPDIR/om-calls/2" ]
    [ "$(cat "$BATS_TMPDIR/om-calls/2")" = "curl -s -p /api/v0/stemcell_assignments" ]
    [ -e "$BATS_TMPDIR/om-calls/3" ]
    [ "$(cat "$BATS_TMPDIR/om-calls/3")" = "configure-product --config ./config.json" ]
    [ -e "$BATS_TMPDIR/om-calls/4" ]
    [ "$(cat "$BATS_TMPDIR/om-calls/4")" = "apply-changes" ]
}

@test "setting selective deploy to false runs a full apply-changes" {
    mock_set_output "${mock_tileinspect}" '{
            "name": "my-tile",
            "product_version": "1.2.3"
        }'

    run ./install-tile.sh ./my-tile.pivotal ./config.json false
    [ "$status" -eq 0 ]
    [ -e "$BATS_TMPDIR/om-calls/4" ]
    [ "$(cat "$BATS_TMPDIR/om-calls/4")" = "apply-changes" ]
}

@test "setting selective deploy to true runs a full apply-changes" {
    mock_set_output "${mock_tileinspect}" '{
            "name": "my-tile",
            "product_version": "1.2.3"
        }'

    run ./install-tile.sh ./my-tile.pivotal ./config.json true
    [ "$status" -eq 0 ]
    [ -e "$BATS_TMPDIR/om-calls/4" ]
    [ "$(cat "$BATS_TMPDIR/om-calls/4")" = "apply-changes --product-name my-tile" ]
}
