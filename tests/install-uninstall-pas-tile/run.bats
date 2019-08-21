#!/usr/bin/env bats
load ../../tools/test-helpers

setup() {
    export mock_install_tile_sh="$(mock_bin install-tile.sh)"
    export mock_uninstall_tile_sh="$(mock_bin uninstall-tile.sh)"
    export mock_log_dependencies_sh="$(mock_bin log-dependencies.sh)"
    export mock_mrlog="$(mock_bin mrlog)"
    export mock_needs="$(mock_bin needs)"
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
    [ "$(mock_get_call_num "${mock_log_dependencies_sh}")" = "1" ]
    [ "$(mock_get_call_num "${mock_install_tile_sh}")" = "1" ]
    [ "$(mock_get_call_args "${mock_install_tile_sh}" 1)" = "/input/tile/test-tile.pivotal /input/tile-config/test-tile.yml false" ]

    [ "$(mock_get_call_num "${mock_uninstall_tile_sh}")" = "1" ]
    [ "$(mock_get_call_args "${mock_uninstall_tile_sh}" 1)" = "/input/tile/test-tile.pivotal false" ]

    [ "$(mock_get_call_num "${mock_mrlog}")" = "8" ]
}

@test "setting USE_FULL_DEPLOY passes that along to the script" {
    export TILE_NAME=test-tile.pivotal
    export TILE_CONFIG=test-tile.yml
    export USE_FULL_DEPLOY=true

    run ${BATS_TEST_DIRNAME}/run.sh

    status_equals 0
    [ "$(mock_get_call_num "${mock_needs}")" = "1" ]
    [ "$(mock_get_call_num "${mock_log_dependencies_sh}")" = "1" ]
    [ "$(mock_get_call_num "${mock_install_tile_sh}")" = "1" ]
    [ "$(mock_get_call_args "${mock_install_tile_sh}" 1)" = "/input/tile/test-tile.pivotal /input/tile-config/test-tile.yml true" ]

    [ "$(mock_get_call_num "${mock_uninstall_tile_sh}")" = "1" ]
    [ "$(mock_get_call_args "${mock_uninstall_tile_sh}" 1)" = "/input/tile/test-tile.pivotal true" ]

    [ "$(mock_get_call_num "${mock_mrlog}")" = "8" ]
}

@test "test exits before installing if needs are not met" {
    mock_set_status "${mock_needs}" 1

    run ${BATS_TEST_DIRNAME}/run.sh

    status_equals 1
    [ "$(mock_get_call_num "${mock_needs}")" = "1" ]
    [ "$(mock_get_call_num "${mock_log_dependencies_sh}")" = "0" ]
    [ "$(mock_get_call_num "${mock_install_tile_sh}")" = "0" ]
    [ "$(mock_get_call_num "${mock_uninstall_tile_sh}")" = "0" ]
    output_equals "needs check failed"
}

@test "returns error code when install tile fails" {
    mock_set_status "${mock_install_tile_sh}" 1

    run ${BATS_TEST_DIRNAME}/run.sh

    status_equals 1
    output_equals "install-tile failed"
}

@test "returns error code when uninstall tile fails" {
    mock_set_status "${mock_uninstall_tile_sh}" 1

    run ${BATS_TEST_DIRNAME}/run.sh

    status_equals 1
    output_equals "uninstall-tile failed"
}
