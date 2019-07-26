load temp/bats-mock # docs at https://github.com/grayhemp/bats-mock

setup() {
    export BATS_TMPDIR
    mkdir -p "$BATS_TMPDIR/bin"

    export mock_om="$(mock_create)"
    ln -sf "${mock_om}" "${BATS_TMPDIR}/bin/om"

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
}

@test "happy path calls the right tools" {
    mock_set_output "${mock_om}" '{
        "stemcell_library": [{
            "infrastructure": "some-required-stemcell"
        }]
    }' 3

    mock_set_output "${mock_tileinspect}" '{
            "name": "my-tile",
            "product_version": "1.2.3"
        }'

    run ./install-tile.sh tile.pivotal config.json
    [ "$status" -eq 0 ]
    [ "$(mock_get_call_args ${mock_om} 1)" == "upload-product --product tile.pivotal" ]
    [ "$(mock_get_call_args ${mock_om} 2)" == "stage-product --product-name my-tile --product-version 1.2.3" ]
    [ "$(mock_get_call_args ${mock_om} 3)" == "curl -s -p /api/v0/stemcell_assignments" ]
    [ "$(mock_get_call_args ${mock_upload_and_assign_stemcells})" == "some-required-stemcell" ]
    [ "$(mock_get_call_args ${mock_build_tile_config})" == "my-tile config.json" ]
    [ "$(mock_get_call_args ${mock_om} 4)" == "configure-product --config ./config.json" ]
    [ "$(mock_get_call_args ${mock_om} 5)" == "apply-changes" ]
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
    mock_set_status "${mock_om}" 1

    run ./install-tile.sh tile.pivotal config.yml

    [ "$(mock_get_call_num ${mock_om})" -eq 1 ]
    [ "$(mock_get_call_args ${mock_om})" == "upload-product --product tile.pivotal" ]

    [ "$status" -eq 1 ]
    [ -n "$(echo "${output}" | grep "Failed to upload product tile.pivotal")" ]
    [ -n "$(echo "${output}" | grep "If you see an 'x509' error, try setting OM_SKIP_SSL_VALIDATION=true")" ]
}

@test "exits if om stage-product fails" {
    mock_set_output "${mock_tileinspect}" '{
        "name": "my-tile",
        "product_version": "1.2.3"
    }'

    mock_set_status "${mock_om}" 0 1
    mock_set_status "${mock_om}" 1 2

    run ./install-tile.sh tile.pivotal config.yml
    [ "$(mock_get_call_num ${mock_om})" -eq 2 ]

    [ "$(mock_get_call_args ${mock_om} 1)" == "upload-product --product tile.pivotal" ]
    [ "$(mock_get_call_args ${mock_om} 2)" == "stage-product --product-name my-tile --product-version 1.2.3" ]

    [ "$status" -eq 1 ]
    [ -n "$(echo "${output}" | grep "Failed to stage version 1.2.3 of my-tile")" ]
    [ -n "$(echo "${output}" | grep "If you see an 'x509' error, try setting OM_SKIP_SSL_VALIDATION=true")" ]
}

@test "exits if om configure-product fails" {
    mock_set_output "${mock_om}" '{
        "stemcell_library": [
            {
                "infrastructure": "some-required-stemcell"
            }
        ]
    }' 3
    mock_set_status "${mock_om}" 1 4

    mock_set_output "${mock_tileinspect}" '{
        "name": "my-tile",
        "product_version": "1.2.3"
    }'

    run ./install-tile.sh tile.pivotal config.yml

    [ "$(mock_get_call_num ${mock_om})" -eq 4 ]

    [ "$(mock_get_call_args ${mock_om} 1)" == "upload-product --product tile.pivotal" ]
    [ "$(mock_get_call_args ${mock_om} 2)" == "stage-product --product-name my-tile --product-version 1.2.3" ]
    [ "$(mock_get_call_args ${mock_om} 3)" == "curl -s -p /api/v0/stemcell_assignments" ]
    [ "$(mock_get_call_args ${mock_upload_and_assign_stemcells})" == "some-required-stemcell" ]

    [ "$(mock_get_call_args ${mock_om} 4)" == "configure-product --config ./config.json" ]

    [ "$status" -eq 1 ]
    [ -n "$(echo "${output}" | grep "Failed to configure product my-tile")" ]
    [ -n "$(echo "${output}" | grep "If you see an 'x509' error, try setting OM_SKIP_SSL_VALIDATION=true")" ]
}

@test "exits if om apply-changes fails" {
    mock_set_status "${mock_om}" 1 5

    run ./install-tile.sh tile.pivotal config.yml
    [ "$status" -eq 1 ]
    [ -n "$(echo "${output}" | grep "Failed to apply changes")" ]
    [ -n "$(echo "${output}" | grep "If you see an 'x509' error, try setting OM_SKIP_SSL_VALIDATION=true")" ]

    [ "$(mock_get_call_num ${mock_om})" -eq 5 ]
    [ "$(mock_get_call_args ${mock_om} 5)" == "apply-changes" ]
}

@test "setting selective deploy to false runs a full apply-changes" {
    mock_set_output "${mock_om}" '{
        "stemcell_library": [{
            "infrastructure": "some-required-stemcell"
        }]
    }' 3

    mock_set_output "${mock_tileinspect}" '{
            "name": "my-tile",
            "product_version": "1.2.3"
        }'

    run ./install-tile.sh tile.pivotal config.json false
    [ "$status" -eq 0 ]
    [ "$(mock_get_call_args ${mock_om} 5)" == "apply-changes" ]
}

@test "setting selective deploy to true runs a selective apply-changes" {
    mock_set_output "${mock_om}" '{
        "stemcell_library": [{
            "infrastructure": "some-required-stemcell"
        }]
    }' 3

    mock_set_output "${mock_tileinspect}" '{
            "name": "my-tile",
            "product_version": "1.2.3"
        }'

    run ./install-tile.sh tile.pivotal config.json true
    [ "$status" -eq 0 ]
    [ "$(mock_get_call_args ${mock_om} 5)" == "apply-changes --product-name my-tile" ]
}
