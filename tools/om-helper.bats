load test-helpers

setup() {
    export mock_om="$(mock_bin om)"
    export PATH="${BIN_MOCKS}:${PATH}"
}

teardown() {
    clean_bin_mocks
}

@test "displays usage when no parameters provided" {
    run ./om-helper.sh
    [ "$status" -eq 1 ]
    [ "$output" = "usage: om-helper.sh stemcell-assignments [--unmet]" ]
}

@test "displays usage when unknown paraeters provided" {
    run ./om-helper.sh not-a-command
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = "Unknown command: not-a-command" ]
    [ "${lines[1]}" = "usage: om-helper.sh stemcell-assignments [--unmet]" ]
}

@test "displays usage with help command" {
    run ./om-helper.sh help
    [ "$status" -eq 0 ]
    [ "$output" = "usage: om-helper.sh stemcell-assignments [--unmet]" ]
}

@test "errors if om fails" {
    mock_set_status "${mock_om}" 1
    run ./om-helper.sh stemcell-assignments
    [ "$status" -eq 1 ]
}

@test "returns empty array when no products" {
    mock_set_output "${mock_om}" '{ "products": [] }'
    run ./om-helper.sh stemcell-assignments
    [ "$status" -eq 0 ]
    [ "$output" = "[]" ]
}

@test "returns all required stemcells for products" {
    mock_set_output "${mock_om}" '{
    "products" : [{
        "guid": "product-1-abcfefg12345",
        "required_stemcell_os": "ubuntu-xenial",
        "required_stemcell_version": "250.63",
        "staged_stemcell_version": null
    }, {
        "guid": "product-2-abcfefg12345",
        "required_stemcell_os": "ubuntu-xenial",
        "required_stemcell_version": "250.63",
        "staged_stemcell_version": "250.63"
    }]
}'
    run ./om-helper.sh stemcell-assignments
    [ "$status" -eq 0 ]
    [ "$output" = '[{"product":"product-1-abcfefg12345","os":"ubuntu-xenial","version":"250.63","unmet":true},{"product":"product-2-abcfefg12345","os":"ubuntu-xenial","version":"250.63","unmet":false}]' ]
}

@test "returns unmet stemcells for products when given --unmet flag" {
    mock_set_output "${mock_om}" '{
    "products" : [{
        "guid": "product-1-abcfefg12345",
        "required_stemcell_os": "ubuntu-xenial",
        "required_stemcell_version": "250.63",
        "staged_stemcell_version": null
    }, {
        "guid": "product-2-abcfefg12345",
        "required_stemcell_os": "ubuntu-xenial",
        "required_stemcell_version": "250.63",
        "staged_stemcell_version": "250.63"
    }]
}'
    run ./om-helper.sh stemcell-assignments --unmet
    [ "$status" -eq 0 ]
    [ "$output" = '[{"product":"product-1-abcfefg12345","os":"ubuntu-xenial","version":"250.63","unmet":true}]' ]
}

@test "returns empty list when there are no unmet stemcells and given --unmet flag" {
    mock_set_output "${mock_om}" '{
    "products" : [{
        "guid": "product-1-abcfefg12345",
        "required_stemcell_os": "ubuntu-xenial",
        "required_stemcell_version": "250.63",
        "staged_stemcell_version": "250.63"
    }, {
        "guid": "product-2-abcfefg12345",
        "required_stemcell_os": "ubuntu-xenial",
        "required_stemcell_version": "250.63",
        "staged_stemcell_version": "250.63"
    }]
}'
    run ./om-helper.sh stemcell-assignments --unmet
    [ "$status" -eq 0 ]
    [ "$output" = '[]' ]
}
