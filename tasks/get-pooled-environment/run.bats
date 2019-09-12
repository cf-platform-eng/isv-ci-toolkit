#!/usr/bin/env bats
load ../../tools/test-helpers

setup() {
    export mock_needs="$(mock_bin needs)"
    export mock_smith="$(mock_bin smith)"
    export PATH="${BIN_MOCKS}:${PATH}"
    export TASK_OUTPUT="$BATS_TMPDIR/output"
    mkdir -p "${TASK_OUTPUT}"
}

teardown() {
    clean_bin_mocks
}

@test "happy path" {
    mock_set_output "${mock_smith}" '# Environment vividcrimson was successfully claimed. To use it as the default environment, try:
export env=vividcrimson' 1
    mock_set_output "${mock_smith}" "smith list output" 2

    run ./run.sh
    status_equals 0

    output_says "Claimed environment vividcrimson"

    [[ -e "${TASK_OUTPUT}/environment.json" ]]
    [[ $(cat "${TASK_OUTPUT}/environment.json") = "smith list output" ]]
}
