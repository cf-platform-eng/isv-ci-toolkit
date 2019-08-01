load test-helpers

setup() {
    export mock_om="$(mock_bin om)"
    export mock_build_tile_config="$(mock_bin build-tile-config.sh)"
    export mock_upload_and_assign_stemcells="$(mock_bin upload_and_assign_stemcells.sh)"
    export mock_tileinspect="$(mock_bin tileinspect)"
    export mock_compare_staged_config="$(mock_bin compare-staged-config.sh)"

    export PATH="${BIN_MOCKS}:${PATH}"
}

teardown() {
    clean_bin_mocks
}

@test "happy path calls the right tools" {
    mock_set_status "${mock_compare_staged_config}" 0

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

    [ "$(mock_get_call_num ${mock_om})" -eq 6 ]
    [ "$(mock_get_call_args ${mock_om} 1)" == "upload-product --product tile.pivotal" ]
    [ "$(mock_get_call_args ${mock_om} 2)" == "stage-product --product-name my-tile --product-version 1.2.3" ]
    [ "$(mock_get_call_args ${mock_om} 3)" == "curl -s -p /api/v0/stemcell_assignments" ]
    # TODO check this outputs to the correct file
    [ "$(mock_get_call_args ${mock_upload_and_assign_stemcells})" == "some-required-stemcell" ]
    # TODO need a seperate test to ensure we handle build tile config errors (it should stop the run)
    # Also worth adding section(s) to inside build-tile-config.sh
    [ "$(mock_get_call_args ${mock_build_tile_config})" == "my-tile config.json" ]

    [ "$(mock_get_call_num ${mock_compare_staged_config})" -eq 1 ]
    [ "$(mock_get_call_args ${mock_compare_staged_config})" == "my-tile ${PWD}/config.json" ]
    # TODO check this outputs right dependencies
    [ "$(mock_get_call_args ${mock_om} 4)" == "curl --path /api/v0/stemcell_assignments" ]
    [ "$(mock_get_call_args ${mock_om} 5)" == "configure-product --config ./config.json" ]
    [ "$(mock_get_call_args ${mock_om} 6)" == "apply-changes" ]
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

@test "exits if compare-staged-config fails" {
    mock_set_output "${mock_compare_staged_config}" 'Failed to compare configurations'
    mock_set_status "${mock_compare_staged_config}" 1

    mock_set_output "${mock_tileinspect}" '{
        "name": "my-tile",
        "product_version": "1.2.3"
    }'

    mock_set_status "${mock_om}" 0 1
    mock_set_status "${mock_om}" 0 2

    run ./install-tile.sh path/to/tile.pivotal path/to/config.yml
    [ "$(mock_get_call_num ${mock_om})" -eq 2 ]

    [ "$(mock_get_call_args ${mock_om} 1)" == "upload-product --product path/to/tile.pivotal" ]
    [ "$(mock_get_call_args ${mock_om} 2)" == "stage-product --product-name my-tile --product-version 1.2.3" ]

    [ "$(mock_get_call_num ${mock_compare_staged_config})" -eq 1 ]
    [ "$(mock_get_call_args ${mock_compare_staged_config})" == "my-tile ${PWD}/config.json" ]

    [ "$status" -eq 1 ]
    output_says "Failed to compare configurations"

}

@test "exits if om configure-product fails" {
    mock_set_output "${mock_om}" '{
        "stemcell_library": [
            {
                "infrastructure": "some-required-stemcell"
            }
        ]
    }' 3
    mock_set_status "${mock_om}" 1 5

    mock_set_output "${mock_tileinspect}" '{
        "name": "my-tile",
        "product_version": "1.2.3"
    }'

    run ./install-tile.sh tile.pivotal config.yml

    [ "$(mock_get_call_num ${mock_om})" -eq 5 ]

    [ "$(mock_get_call_args ${mock_om} 1)" == "upload-product --product tile.pivotal" ]
    [ "$(mock_get_call_args ${mock_om} 2)" == "stage-product --product-name my-tile --product-version 1.2.3" ]
    [ "$(mock_get_call_args ${mock_om} 3)" == "curl -s -p /api/v0/stemcell_assignments" ]
    [ "$(mock_get_call_args ${mock_upload_and_assign_stemcells})" == "some-required-stemcell" ]
    [ "$(mock_get_call_args ${mock_om} 4)" == "curl --path /api/v0/stemcell_assignments" ]
    [ "$(mock_get_call_args ${mock_om} 5)" == "configure-product --config ./config.json" ]

    [ "$status" -eq 1 ]
    [ -n "$(echo "${output}" | grep "Failed to configure product my-tile")" ]
    [ -n "$(echo "${output}" | grep "If you see an 'x509' error, try setting OM_SKIP_SSL_VALIDATION=true")" ]
}
@test "exits if list stemcells fails" {
    mock_set_status "${mock_om}" 1 4

    run ./install-tile.sh tile.pivotal config.yml
    [ "$status" -eq 1 ]
    [ "$(mock_get_call_num ${mock_om})" -eq 4 ]
    [ "$(mock_get_call_args ${mock_om} 4)" == "curl --path /api/v0/stemcell_assignments" ]
}

@test "exits if om apply-changes fails" {
    mock_set_status "${mock_om}" 1 6

    run ./install-tile.sh tile.pivotal config.yml
    [ "$status" -eq 1 ]
    [ -n "$(echo "${output}" | grep "Failed to apply changes")" ]
    [ -n "$(echo "${output}" | grep "If you see an 'x509' error, try setting OM_SKIP_SSL_VALIDATION=true")" ]

    [ "$(mock_get_call_num ${mock_om})" -eq 6 ]
    [ "$(mock_get_call_args ${mock_om} 6)" == "apply-changes" ]
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
    [ "$(mock_get_call_args ${mock_om} 6)" == "apply-changes" ]
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
    [ "$(mock_get_call_args ${mock_om} 6)" == "apply-changes --product-name my-tile" ]
}
