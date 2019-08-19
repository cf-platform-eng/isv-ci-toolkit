load test-helpers

setup() {
    export mock_om="$(mock_bin om)"
    export mock_tileinspect="$(mock_bin tileinspect)"
    export PATH="${BIN_MOCKS}:${PATH}"
}

teardown() {
    clean_bin_mocks
}

@test "displays usage when no parameters provided" {
    run ./uninstall-tile.sh
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = "usage: uninstall-tile.sh <tile> [<full deploy>]" ]
    [ "${lines[1]}" = "    tile - path to a .pivotal file" ]
    [ "${lines[2]}" = "    full deploy - if true, deploys all products, otherwise only deploys this tile (default false)" ]
}

@test "exits if om unstage-product fails" {
    mock_set_status "${mock_om}" 1 1
    mock_set_output "${mock_tileinspect}" '{
        "name": "my-tile",
        "product_version": "1.2.3"
    }'        
    run ./uninstall-tile.sh tile.pivotal
    [ "$status" -eq 1 ]
    output_says "Failed to unstage product my-tile"
}

@test "exits if om apply-changes fails" {
    mock_set_status "${mock_om}" 1 2
    run ./uninstall-tile.sh tile.pivotal
    [ "$status" -eq 1 ]
    output_says "Failed to apply changes"
}

@test "exits if om delete-product fails" {
    mock_set_status "${mock_om}" 1 3
    mock_set_output "${mock_tileinspect}" '{
        "name": "my-tile",
        "product_version": "1.2.3"
    }'        
    run ./uninstall-tile.sh tile.pivotal
    [ "$status" -eq 1 ]
    [ "$output" = "Failed to delete version 1.2.3 of my-tile" ]
}

@test "happy path calls the right om calls" {
    mock_set_output "${mock_tileinspect}" '{
        "name": "my-tile",
        "product_version": "1.2.3"
    }'

    run ./uninstall-tile.sh tile.pivotal true
    [ "$status" -eq 0 ]
    [ "$(mock_get_call_num "${mock_om}")" = "3" ]
    [ "$(mock_get_call_args "${mock_om}" 1)" = "unstage-product --product-name my-tile" ]
    [ "$(mock_get_call_args "${mock_om}" 2)" = "apply-changes" ]
    [ "$(mock_get_call_args "${mock_om}" 3)" = "delete-product --product-name my-tile --product-version 1.2.3" ]
}

@test "setting full deploy to true runs a full apply-changes" {
    mock_set_output "${mock_tileinspect}" '{
        "name": "my-tile",
        "product_version": "1.2.3"
    }'

    run ./uninstall-tile.sh tile.pivotal true
    [ "$status" -eq 0 ]
    [ "$(mock_get_call_args "${mock_om}" 2)" = "apply-changes" ]
}

@test "setting full deploy to false runs a selective apply-changes" {
    mock_set_output "${mock_tileinspect}" '{
        "name": "my-tile",
        "product_version": "1.2.3"
    }'

    run ./uninstall-tile.sh tile.pivotal false
    [ "$status" -eq 0 ]
    [ "$(mock_get_call_args "${mock_om}" 2)" = "apply-changes --product-name my-tile" ]
}
