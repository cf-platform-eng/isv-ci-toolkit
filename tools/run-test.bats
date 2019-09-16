load test-helpers

setup() {
    export mock_docker="$(mock_bin docker)"
    export PATH="${BIN_MOCKS}:${PATH}"
}

teardown() {
    clean_bin_mocks
}

@test "displays usage when no parameters provided" {
    run ./run-test.sh
    status_equals 1
    output_equals "usage: run-test.sh <test image> [<additional parameters to docker>]"
}

@test "gets the list of needs and builds a command" {
    mock_set_output "${mock_docker}" '[
        {"type": "environment_variable", "name": "MY_VAR_1"},
        {"type": "environment_variable", "name": "MY_VAR_2"}
    ]' 1
    run ./run-test.sh my-image
    output_says "docker run -it -e MY_VAR_1 -e MY_VAR_2 my-image"
    [ "$(mock_get_call_args ${mock_docker} 2)" == "run -it -e MY_VAR_1 -e MY_VAR_2 my-image" ]
}

@test "extra args are passed to the command" {
    mock_set_output "${mock_docker}" '[
        {"type": "environment_variable", "name": "MY_VAR_1"},
        {"type": "environment_variable", "name": "MY_VAR_2"}
    ]' 1
    run ./run-test.sh my-image ls /input/*.sh
    output_says "docker run -it -e MY_VAR_1 -e MY_VAR_2 my-image ls /input/*.sh"
    [ "$(mock_get_call_args ${mock_docker} 2)" == "run -it -e MY_VAR_1 -e MY_VAR_2 my-image ls /input/*.sh" ]
}

@test "fails if cannot get the needs" {
    mock_set_status "${mock_docker}" 1
    run ./run-test.sh my-image
    status_equals 1
    output_says "Failed to get the needs of this test"
}