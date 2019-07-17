setup() {
    mkdir -p "$BATS_TMPDIR/input"
    cat > "$BATS_TMPDIR/input/environment.json" <<'EOF'
{
    "paver_paving_output": {
        "ops_manager_dns": {
            "value": "pcf.famousdoctor.cfplatformeng.com"
        }
    }
}
EOF
    cat > "$BATS_TMPDIR/input/credentials.json" <<'EOF'
{
    "username": "pete",
    "password": "super-secret-1"
}
EOF
}

teardown() {
    rm -rf "$BATS_TMPDIR/input"
}

@test "asks for an environment file when no parameters are provided" {
    run ./setup_om.sh
    [ "$status" -eq 1 ]
    [ "$output" = "no environment file provided" ]
}

@test "asks for a credendials file when only one parameter is provided" {
    run ./setup_om.sh env-file
    [ "$status" -eq 1 ]
    [ "$output" = "no cred file provided" ]
}

@test "runs successfully with the correct files" {
    run ./setup_om.sh "$BATS_TMPDIR/input/environment.json" "$BATS_TMPDIR/input/credentials.json"
    [ "$status" -eq 0 ]
}

@test "sets the right environment variables" {
    . ./setup_om.sh "$BATS_TMPDIR/input/environment.json" "$BATS_TMPDIR/input/credentials.json"
    [ "${OM_TARGET}" = "pcf.famousdoctor.cfplatformeng.com" ]
    [ "${OM_USERNAME}" = "pete" ]
    [ "${OM_PASSWORD}" = "super-secret-1" ]
    [ "${OM_SKIP_SSL_VALIDATION}" = "true" ]
}

# @test "exits if the target is missing" {
#     run ./setup_om.sh "$BATS_TMPDIR/input/environment.json" "$BATS_TMPDIR/input/credentials.json"
#     [ "$status" -eq 1 ]
# }
