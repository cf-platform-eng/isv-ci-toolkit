load test-helpers

setup() {
    export mock_om="$(mock_bin om)"
    export mock_tileinspect="$(mock_bin tileinspect)"
    export PATH="${BIN_MOCKS}:${PATH}"

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
{
    "product-name": "some tile",
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
}
EOF
}

teardown() {
    rm "$BATS_TMPDIR/pete-config.json"
    rm "$BATS_TMPDIR/pete-config.yml"
    clean_bin_mocks
}

@test "displays usage when no parameters provided" {
    run ./generate-config-for-tile.sh
    [ "$status" -eq 1 ]
    [ "$output" = "usage: generate-config-for-tile.sh <tile> <config.yml|config.json>" ]
}

@test "displays usage when only one parameter provided" {
    run ./generate-config-for-tile.sh test-tile
    [ "$status" -eq 1 ]
    [ "$output" = "usage: generate-config-for-tile.sh <tile> <config.yml|config.json>" ]
}

@test "exits if om fails" {
    mock_set_status "${mock_om}" 1
    run ./generate-config-for-tile.sh test-tile pete-config.yml
    [ "$status" -eq 1 ]
    [ "$output" = "Failed to get cloud_config from OpsManager" ]
}

@test "exits if tileinspect fails" {
    mock_set_status "${mock_tileinspect}" 1
    run ./generate-config-for-tile.sh test-tile pete-config.yml
    [ "$status" -eq 1 ]
    [ "$output" = "Failed to get metadata from test-tile" ]
}

@test "builds valid config from json" {
    mock_set_output "${mock_tileinspect}" '{
        "name": "my-tile",
        "product_version": "1.2.3",
        "job_types": [{"job": "a job"}]
    }'
    mock_set_output "${mock_om}" '{"cloud_config":{"azs":[{"name":"us-c-f"},{"name":"us-c-c"}],"networks":[{"name":"m-management-s"},{"name":"m-pas-s"},{"name":"m-services-s"}],"vm_types":[{"name":"micro"},{"name":"micro.cpu"},{"name":"small"},{"name":"small.disk"}],"disk_types":[{"name":"1024"},{"name":"2048"},{"name":"5120"},{"name":"10240"}]}}'
    run ./generate-config-for-tile.sh test-tile "$BATS_TMPDIR/pete-config.json"
    [ "$status" -eq 0 ]
    [ `echo $output | jq -r '.["product-name"]'` = "my-tile" ]
    [ `echo $output | jq -r '.["network-properties"].network.name'` = "m-services-s" ]
    [ `echo $output | jq -r '.["network-properties"].service_network.name'` = "m-services-s" ]
    [ `echo $output | jq -r '.["network-properties"].singleton_availability_zone.name'` = "us-c-f" ]
    [ `echo $output | jq -r '.["network-properties"].other_availability_zones[0].name'` = "us-c-f" ]
    [ `echo $output | jq -r '.["network-properties"].other_availability_zones[1].name'` = "us-c-c" ]
    [ `echo $output | jq -r '.["product-properties"][".properties.apply_open_security_group"].value'` = "false" ]
}

@test "builds valid config from yml" {
    mock_set_output "${mock_tileinspect}" '{
        "name": "my-tile",
        "product_version": "1.2.3",
        "job_types": [{"job": "a job"}]
    }'
    mock_set_output "${mock_om}" '{"cloud_config":{"azs":[{"name":"us-c-f"},{"name":"us-c-c"}],"networks":[{"name":"m-management-s"},{"name":"m-pas-s"},{"name":"m-services-s"}],"vm_types":[{"name":"micro"},{"name":"micro.cpu"},{"name":"small"},{"name":"small.disk"}],"disk_types":[{"name":"1024"},{"name":"2048"},{"name":"5120"},{"name":"10240"}]}}'
    run ./generate-config-for-tile.sh test-tile "$BATS_TMPDIR/pete-config.yml"
    [ "$status" -eq 0 ]
    [ `echo $output | jq -r '.["product-name"]'` = "my-tile" ]
    [ `echo $output | jq -r '.["network-properties"].network.name'` = "m-services-s" ]
    [ `echo $output | jq -r '.["network-properties"].service_network.name'` = "m-services-s" ]
    [ `echo $output | jq -r '.["network-properties"].singleton_availability_zone.name'` = "us-c-f" ]
    [ `echo $output | jq -r '.["network-properties"].other_availability_zones[0].name'` = "us-c-f" ]
    [ `echo $output | jq -r '.["network-properties"].other_availability_zones[1].name'` = "us-c-c" ]
    [ `echo $output | jq -r '.["product-properties"][".properties.apply_open_security_group"].value'` = "false" ]
    [ "$(mock_get_call_args ${mock_tileinspect})" == "metadata -t test-tile" ]
}

@test "builds tile config without network config when tile has empty job_types" {
    mock_set_output "${mock_tileinspect}" '{
        "name": "my-tile",
        "product_version": "1.2.3",
        "job_types": []
    }'
    run ./generate-config-for-tile.sh test-tile "$BATS_TMPDIR/pete-config.json"

    [ "$status" -eq 0 ]
    [ `echo $output | jq -r '.["product-name"]'` = "my-tile" ]
    [ `echo $output | jq -r '.["network-properties"]'` = "null" ]
}

@test "properly handles no job types from tileinspect" {
        mock_set_output "${mock_tileinspect}" '{
        "name": "my-tile",
        "product_version": "1.2.3"
    }'
    run ./generate-config-for-tile.sh test-tile "$BATS_TMPDIR/pete-config.json"

    [ "$status" -eq 0 ]
    [ `echo $output | jq -r '.["product-name"]'` = "my-tile" ]
    [ `echo $output | jq -r '.["network-properties"]'` = "null" ]
}

@test "replaces placeholders" {
    mock_set_output "${mock_tileinspect}" '{
        "name": "my-tile",
        "product_version": "1.2.3",
        "job_types": [{"job": "a job"}]
    }'
    mock_set_output "${mock_om}" '{"cloud_config":{"azs":[{"name":"us-c-f"},{"name":"us-c-c"}],"networks":[{"name":"m-management-s"},{"name":"m-pas-s"},{"name":"m-services-s"}],"vm_types":[{"name":"micro"},{"name":"micro.cpu"},{"name":"small"},{"name":"small.disk"}],"disk_types":[{"name":"1024"},{"name":"2048"},{"name":"5120"},{"name":"10240"}]}}'
    run ./generate-config-for-tile.sh test-name "$BATS_TMPDIR/pete-config.yml"
    [ "$status" -eq 0 ]
    [ `echo $output | jq -r '.["product-properties"][".properties.some_availability_zone"].value'` = "us-c-f" ]
    [ `echo $output | jq -r '.["product-properties"][".properties.some_vm_type"].value'` = "small" ]
    [ `echo $output | jq -r '.["product-properties"][".properties.some_disk_type"].value'` = "5120" ]
}