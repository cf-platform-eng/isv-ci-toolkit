#!/usr/bin/env bats

setup() {
    mkdir -p "$BATS_TMPDIR/bin"
    echo 'echo ${MOCK_OM_OUTPUT}; exit ${MOCK_OM_RETURN_CODE:-0}' > "$BATS_TMPDIR/bin/om"
    chmod a+x "$BATS_TMPDIR/bin/om"
    export PATH="$BATS_TMPDIR/bin:${PATH}"
}

teardown() {
    rm -rf "$BATS_TMPDIR/bin"
    unset MOCK_OM_OUTPUT
    unset MOCK_OM_RETURN_CODE
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
    export MOCK_OM_OUTPUT=''
    export MOCK_OM_RETURN_CODE=1
    run ./om-helper.sh stemcell-assignments
    [ "$status" -eq 1 ]
}

@test "returns empty array when no products" {
    export MOCK_OM_OUTPUT='{ "products": [] }'
    run ./om-helper.sh stemcell-assignments
    [ "$status" -eq 0 ]
    [ "$output" = "[]" ]
}

@test "returns all required stemcells for products" {
    export MOCK_OM_OUTPUT='{
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
    export MOCK_OM_OUTPUT='{
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
    export MOCK_OM_OUTPUT='{
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
