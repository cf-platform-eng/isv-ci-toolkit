#!/usr/bin/env bats

setup() {
    mkdir -p "$BATS_TMPDIR/bin"
    echo 'echo ${MOCK_OM_OUTPUT}; exit ${MOCK_OM_RETURN_CODE:-0}' > "$BATS_TMPDIR/bin/om"
    chmod a+x "$BATS_TMPDIR/bin/om"
    export PATH="$BATS_TMPDIR/bin:${PATH}"
    cat <<EOF > "$BATS_TMPDIR/pete-config.yml"
product-properties:
  ".properties.apply_open_security_group":
    value: false
    type: boolean
  ".properties.allow_paid_service_plans":
    value: false
    type: boolean
  ".properties.org":
    value: test-tile-org
    type: string
  ".properties.space":
    value: test-tile-space
    type: string
EOF
}

teardown() {
    rm -rf "$BATS_TMPDIR/bin"
    rm "$BATS_TMPDIR/pete-config.yml"
    unset MOCK_OM_OUTPUT
    unset MOCK_OM_RETURN_CODE
}

@test "displays usage when no parameters provided" {
    run ./build-tile-config.sh
    [ "$status" -eq 1 ]
    [ "$output" = "usage: build-tole-config.sh <product name> <config.yml>" ]
}

@test "displays usage when only one parameter provided" {
    run ./build-tile-config.sh test-name
    [ "$status" -eq 1 ]
    [ "$output" = "usage: build-tole-config.sh <product name> <config.yml>" ]
}

@test "exits if om fails" {
    export MOCK_OM_RETURN_CODE=1
    run ./build-tile-config.sh test-name pete-config.yml
    [ "$status" -eq 1 ]
    [ "$output" = "Failed to get cloud_config from OpsManager" ]
}

@test "builds valid config" {
    export MOCK_OM_OUTPUT='{"cloud_config":{"azs":[{"name":"us-c-f"},{"name":"us-c-c"}],"networks":[{"name":"m-management-s"},{"name":"m-pas-s"},{"name":"m-services-s"}],"vm_types":[{"name":"micro"},{"name":"micro.cpu"},{"name":"small"},{"name":"small.disk"}],"disk_types":[{"name":"1024"},{"name":"2048"},{"name":"5120"},{"name":"10240"}]}}'
    run ./build-tile-config.sh test-name "$BATS_TMPDIR/pete-config.yml"
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "product-name: test-name" ]
    [ "${lines[3]}" = "    name: m-services-s" ]
    [ "${lines[5]}" = "    name: m-services-s" ]
    [ "${lines[6]}" = '  other_availability_zones: [{"name":"us-c-f"},{"name":"us-c-c"}]' ]
    [ "${lines[8]}" = "    name: us-c-f" ]    
    [ "${lines[9]}" = "product-properties:" ]    
    [ "${lines[10]}" = '  ".properties.apply_open_security_group":' ]
}

