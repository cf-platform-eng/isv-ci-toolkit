#!/usr/bin/env bats
load ../../tools/test-helpers

setup() {
    export mock_install_tile_sh="$(mock_bin install-tile.sh)"
    export mock_uninstall_tile_sh="$(mock_bin uninstall-tile.sh)"
    export mock_mrlog="$(mock_bin mrlog)"
    export mock_needs="$(mock_bin needs)"
    export mock_tileinspect="$(mock_bin tileinspect)"
    export PATH="${BIN_MOCKS}:${PATH}"
}

teardown() {
    clean_bin_mocks
}

@test "happy path calls all steps" {
    export TILE_NAME=test-tile.pivotal
    export TILE_CONFIG=test-tile.yml
    unset USE_FULL_DEPLOY

    run ${BATS_TEST_DIRNAME}/run.sh

    status_equals 0
    [ "$(mock_get_call_num "${mock_needs}")" = "1" ]

    [ "$(mock_get_call_num "${mock_tileinspect}")" = "1" ]
    [ "$(mock_get_call_args "${mock_tileinspect}" 1)" = "check-config --tile /input/tile/test-tile.pivotal --config /input/tile-config/test-tile.yml" ]

    [ "$(mock_get_call_num "${mock_install_tile_sh}")" = "1" ]
    [ "$(mock_get_call_args "${mock_install_tile_sh}" 1)" = "/input/tile/test-tile.pivotal /input/tile-config/test-tile.yml false" ]

    [ "$(mock_get_call_num "${mock_uninstall_tile_sh}")" = "1" ]
    [ "$(mock_get_call_args "${mock_uninstall_tile_sh}" 1)" = "/input/tile/test-tile.pivotal false" ]

    [ "$(mock_get_call_num "${mock_mrlog}")" = "10" ]
}

@test "setting USE_FULL_DEPLOY passes that along to the script" {
    export TILE_NAME=test-tile.pivotal
    export TILE_CONFIG=test-tile.yml
    export USE_FULL_DEPLOY=true

    run ${BATS_TEST_DIRNAME}/run.sh

    status_equals 0
    [ "$(mock_get_call_args "${mock_install_tile_sh}" 1)" = "/input/tile/test-tile.pivotal /input/tile-config/test-tile.yml true" ]
    [ "$(mock_get_call_args "${mock_uninstall_tile_sh}" 1)" = "/input/tile/test-tile.pivotal true" ]
}

@test "test exits before installing if needs are not met" {
    mock_set_status "${mock_needs}" 1

    run ${BATS_TEST_DIRNAME}/run.sh

    status_equals 1
    [ "$(mock_get_call_num "${mock_needs}")" = "1" ]
    [ "$(mock_get_call_num "${mock_tileinspect}")" = "0" ]
    [ "$(mock_get_call_num "${mock_install_tile_sh}")" = "0" ]
    [ "$(mock_get_call_num "${mock_uninstall_tile_sh}")" = "0" ]
    output_equals "Needs check indicated that the test is not ready to execute"
}

@test "test exits before installing if check-config fails" {
    mock_set_status "${mock_tileinspect}" 1

    run ${BATS_TEST_DIRNAME}/run.sh

    status_equals 1
    [ "$(mock_get_call_num "${mock_needs}")" = "1" ]
    [ "$(mock_get_call_num "${mock_tileinspect}")" = "1" ]
    [ "$(mock_get_call_num "${mock_install_tile_sh}")" = "0" ]
    [ "$(mock_get_call_num "${mock_uninstall_tile_sh}")" = "0" ]
    output_equals "The supplied config file will not work for the tile"
}

@test "returns error code when install tile fails" {
    mock_set_status "${mock_install_tile_sh}" 1

    run ${BATS_TEST_DIRNAME}/run.sh

    status_equals 1
    output_equals "Failed to stage, configure, or deploy the tile"
}

@test "returns error code when uninstall tile fails" {
    mock_set_status "${mock_uninstall_tile_sh}" 1

    run ${BATS_TEST_DIRNAME}/run.sh

    status_equals 1
    output_equals "Failed to uninstall the tile"
}
