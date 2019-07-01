#!/usr/bin/env bats

setup() {
    export BATS_TMPDIR
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
  ".properties.some_availability_zone":
    value: "{az}"
    type: string
  ".properties.some_vm_type":
    value: "{vm_type}"
    type: string
  ".properties.some_disk_type":
    value: "{disk_type}"
    type: string
EOF
    cat <<EOF > "$BATS_TMPDIR/pete-config.json"
"product-properties": {
    ".properties.space": {
        "type": "string",
        "value": "test-tile-space"
    },
    ".properties.allow_paid_service_plans": {
        "type": "boolean",
        "value": false
    },
    ".properties.apply_open_security_group": {
        "type": "boolean",
        "value": false
    },
    ".properties.org": {
        "type": "string",
        "value": "test-tile-org"
    },
    ".properties.some_availability_zone": {
        "type": "string",
        "value": "{az}"
    },
    ".properties.some_vm_type": {
        "type": "string",
        "value": "{vm_type}"
    },
    ".properties.some_disk_type": {
        "type": "string",
        "value": "{disk_type}"
    }
}
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
    [ "$output" = "usage: build-tile-config.sh <product name> <config.yml>" ]
}

@test "displays usage when only one parameter provided" {
    run ./build-tile-config.sh test-name
    [ "$status" -eq 1 ]
    [ "$output" = "usage: build-tile-config.sh <product name> <config.yml>" ]
}

@test "exits if om fails" {
    export MOCK_OM_RETURN_CODE=1
    run ./build-tile-config.sh test-name pete-config.yml
    [ "$status" -eq 1 ]
    [ "$output" = "Failed to get cloud_config from OpsManager" ]
}

@test "exits if cloud config has no networks" {
    export MOCK_OM_OUTPUT='{"cloud_config":{"azs":[{"name":"us-c-f"},{"name":"us-c-c"}],"vm_types":[{"name":"micro"},{"name":"micro.cpu"},{"name":"small"},{"name":"small.disk"}],"disk_types":[{"name":"1024"},{"name":"2048"},{"name":"5120"},{"name":"10240"}]}}'
    run ./build-tile-config.sh test-name pete-config.yml
    [ "$status" -eq 1 ]
    [ "${lines[1]}" = "OpsManager cloud config has no networks" ]
}

@test "exits if cloud config has no availability zones" {
    export MOCK_OM_OUTPUT='{"cloud_config":{"networks":[{"name":"m-management-s"},{"name":"m-pas-s"},{"name":"m-services-s"}],"vm_types":[{"name":"micro"},{"name":"micro.cpu"},{"name":"small"},{"name":"small.disk"}],"disk_types":[{"name":"1024"},{"name":"2048"},{"name":"5120"},{"name":"10240"}]}}'
    run ./build-tile-config.sh test-name pete-config.yml
    [ "$status" -eq 1 ]
    [ "${lines[1]}" = "OpsManager cloud config has no availability zones" ]
}

@test "exits if cloud config has no vm types" {
    export MOCK_OM_OUTPUT='{"cloud_config":{"azs":[{"name":"us-c-f"},{"name":"us-c-c"}],"networks":[{"name":"m-management-s"},{"name":"m-pas-s"},{"name":"m-services-s"}],"disk_types":[{"name":"1024"},{"name":"2048"},{"name":"5120"},{"name":"10240"}]}}'
    run ./build-tile-config.sh test-name pete-config.yml
    [ "$status" -eq 1 ]
    [ "${lines[1]}" = "OpsManager cloud config has no vm types" ]
}

@test "exits if cloud config has no disk types" {
    export MOCK_OM_OUTPUT='{"cloud_config":{"azs":[{"name":"us-c-f"},{"name":"us-c-c"}],"networks":[{"name":"m-management-s"},{"name":"m-pas-s"},{"name":"m-services-s"}],"vm_types":[{"name":"micro"},{"name":"micro.cpu"},{"name":"small"},{"name":"small.disk"}]}}'
    run ./build-tile-config.sh test-name pete-config.yml
    [ "$status" -eq 1 ]
    [ "${lines[1]}" = "OpsManager cloud config has no disk types" ]
}

@test "builds valid config from yml" {
    export MOCK_OM_OUTPUT='{"cloud_config":{"azs":[{"name":"us-c-f"},{"name":"us-c-c"}],"networks":[{"name":"m-management-s"},{"name":"m-pas-s"},{"name":"m-services-s"}],"vm_types":[{"name":"micro"},{"name":"micro.cpu"},{"name":"small"},{"name":"small.disk"}],"disk_types":[{"name":"1024"},{"name":"2048"},{"name":"5120"},{"name":"10240"}]}}'
    run ./build-tile-config.sh test-name "$BATS_TMPDIR/pete-config.yml"
    [ "$status" -eq 0 ]
    [ `echo $output | jq -r '.["product-name"]'` = "test-name" ]
    [ `echo $output | jq -r '.["network-properties"].network.name'` = "m-services-s" ]
    [ `echo $output | jq -r '.["network-properties"].service_network.name'` = "m-services-s" ]
    [ `echo $output | jq -r '.["network-properties"].singleton_availability_zone.name'` = "us-c-f" ]
    [ `echo $output | jq -r '.["network-properties"].other_availability_zones[0].name'` = "us-c-f" ]
    [ `echo $output | jq -r '.["network-properties"].other_availability_zones[1].name'` = "us-c-c" ]
    [ `echo $output | jq -r '.["product-properties"][".properties.apply_open_security_group"].value'` = "false" ]
}

@test "builds valid config from json" {
    export MOCK_OM_OUTPUT='{"cloud_config":{"azs":[{"name":"us-c-f"},{"name":"us-c-c"}],"networks":[{"name":"m-management-s"},{"name":"m-pas-s"},{"name":"m-services-s"}],"vm_types":[{"name":"micro"},{"name":"micro.cpu"},{"name":"small"},{"name":"small.disk"}],"disk_types":[{"name":"1024"},{"name":"2048"},{"name":"5120"},{"name":"10240"}]}}'
    run ./build-tile-config.sh test-name "$BATS_TMPDIR/pete-config.json"
    [ "$status" -eq 0 ]
    [ `echo $output | jq -r '.["product-name"]'` = "test-name" ]
    [ `echo $output | jq -r '.["network-properties"].network.name'` = "m-services-s" ]
    [ `echo $output | jq -r '.["network-properties"].service_network.name'` = "m-services-s" ]
    [ `echo $output | jq -r '.["network-properties"].singleton_availability_zone.name'` = "us-c-f" ]
    [ `echo $output | jq -r '.["network-properties"].other_availability_zones[0].name'` = "us-c-f" ]
    [ `echo $output | jq -r '.["network-properties"].other_availability_zones[1].name'` = "us-c-c" ]
    [ `echo $output | jq -r '.["product-properties"][".properties.apply_open_security_group"].value'` = "false" ]
}

@test "replaces placeholders" {
    export MOCK_OM_OUTPUT='{"cloud_config":{"azs":[{"name":"us-c-f"},{"name":"us-c-c"}],"networks":[{"name":"m-management-s"},{"name":"m-pas-s"},{"name":"m-services-s"}],"vm_types":[{"name":"micro"},{"name":"micro.cpu"},{"name":"small"},{"name":"small.disk"}],"disk_types":[{"name":"1024"},{"name":"2048"},{"name":"5120"},{"name":"10240"}]}}'
    run ./build-tile-config.sh test-name "$BATS_TMPDIR/pete-config.yml"
    [ "$status" -eq 0 ]
    [ `echo $output | jq -r '.["product-properties"][".properties.some_availability_zone"].value'` = "us-c-f" ]
    [ `echo $output | jq -r '.["product-properties"][".properties.some_vm_type"].value'` = "small" ]
    [ `echo $output | jq -r '.["product-properties"][".properties.some_disk_type"].value'` = "5120" ]

    run ./build-tile-config.sh test-name "$BATS_TMPDIR/pete-config.json"
    [ "$status" -eq 0 ]
    [ `echo $output | jq -r '.["product-properties"][".properties.some_availability_zone"].value'` = "us-c-f" ]
    [ `echo $output | jq -r '.["product-properties"][".properties.some_vm_type"].value'` = "small" ]
    [ `echo $output | jq -r '.["product-properties"][".properties.some_disk_type"].value'` = "5120" ]
}
