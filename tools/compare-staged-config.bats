load test-helpers

setup() {
    export mock_om="$(mock_bin om)"
    export PATH="${BIN_MOCKS}:${PATH}"
}

teardown() {
    clean_bin_mocks
}

@test "displays expected and actual config after staging" {
    STUB_CONFIG_FILE="${BATS_TMPDIR}/config.json"
    echo -e '{
        "product-properties": {
            ".properties.something": {
                "value": "my-property"
            }
        }
    }' > "${STUB_CONFIG_FILE}"

    mock_set_output "${mock_om}" '---
    product-name: test-pas-tile
    product-properties:
      .properties.something:
        value: my-property
    ' 1
    mock_set_status "${mock_om}" 0 1

    run ./compare-staged-config.sh my-tile "${STUB_CONFIG_FILE}"
    [ "$status" -eq 0 ]

    [ "$(mock_get_call_num ${mock_om})" -eq 1 ]
    [ "$(mock_get_call_args ${mock_om} 1)" == "staged-config --product-name my-tile" ]

    output_says "section-start: 'expected configuration'"
    output_says "\"product-name\": \"test-pas-tile\""
    output_says "\"product-properties\": {"
    output_says "\".properties.something\": {"
    output_says "\"value\": \"my-property\""
    output_says "section-end: 'expected configuration'"

    output_says "section-start: 'actual configuration'"
    output_says "$(cat ${STUB_CONFIG_FILE})"
    output_says "section-end: 'actual configuration' result: 0"
}

@test "displays error if om staged-config fails" {
    mock_set_status "${mock_om}" 1
    run ./compare-staged-config.sh my-tile path/to/config.yaml
    [ "$status" -eq 1 ]
    output_says "section-start: 'expected configuration'"
    output_says "Failed to get staged config for my-tile"
    output_says "section-end: 'expected configuration' result: 1"
}
