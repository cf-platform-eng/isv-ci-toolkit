load temp/bats-mock # docs at https://github.com/grayhemp/bats-mock

setup() {
    mkdir -p "$BATS_TMPDIR/input"
    cat > "$BATS_TMPDIR/input/credentials.json" <<'EOF'
{
    "client_id": "pete",
    "client_secret": "super-secret-1"
}
EOF

    export BATS_TMPDIR
    mkdir -p "$BATS_TMPDIR/bin"

    export mock_curl="$(mock_create)"
    ln -sf "${mock_curl}" "${BATS_TMPDIR}/bin/curl"

    export mock_sleep="$(mock_create)"
    ln -sf "${mock_sleep}" "${BATS_TMPDIR}/bin/sleep"

    export mock_uaa="$(mock_create)"
    ln -sf "${mock_uaa}" "${BATS_TMPDIR}/bin/uaa"

    chmod a+x "$BATS_TMPDIR/bin"/*
    export PATH="$BATS_TMPDIR/bin:${PATH}"
}

teardown() {
    rm -rf "$BATS_TMPDIR/input"
    rm -rf "$BATS_TMPDIR/bin"
    rm -rf ./output
}

@test "missing credential file" {
    run ./teardown.sh coolinstallation1234 "/this/path/does/not/exist"
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = '"/this/path/does/not/exist" was not found' ]
    [ "${lines[1]}" = "USAGE: teardown <name> <credential file> [<GIPS address>] [<GIPS UAA address>]" ]
    [ "${lines[2]}" = "    name - name of the installation as known by podium/GIPS" ]
    [ "${lines[3]}" = "    credential file - JSON file containing credentials.  Must include:" ]
    [ "${lines[4]}" = "        client_id" ]
    [ "${lines[5]}" = "        client_secret" ]
    [ "${lines[6]}" = "    GIPS address - target podium instance (default: podium.tls.cfapps.io)" ]
    [ "${lines[7]}" = "    GIPS UAA address - override the authentication endpoint for GIPS (default: gips-prod.login.run.pivotal.io)" ]
}

@test "invalid credential file" {
    echo "this is not valid json" > "$BATS_TMPDIR/input/credentials.json"
    run ./teardown.sh coolinstallation1234 "$BATS_TMPDIR/input/credentials.json"
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = "\"$BATS_TMPDIR/input/credentials.json\" is not valid JSON" ]
}

@test "credential file missing important fields" {
    echo '' > "$BATS_TMPDIR/input/credentials.json"
    run ./teardown.sh coolinstallation1234 "$BATS_TMPDIR/input/credentials.json"
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = 'Credential file missing "client_id"' ]

    echo '{}' > "$BATS_TMPDIR/input/credentials.json"
    run ./teardown.sh coolinstallation1234 "$BATS_TMPDIR/input/credentials.json"
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = 'Credential file missing "client_id"' ]

    echo '{"client_id": "pete"}' > "$BATS_TMPDIR/input/credentials.json"
    run ./teardown.sh coolinstallation1234 "$BATS_TMPDIR/input/credentials.json"
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = 'Credential file missing "client_secret"' ]
}

@test "fails to set uaa target" {
    mock_set_status "${mock_uaa}" 1 1
    run ./teardown.sh coolinstallation1234 "$BATS_TMPDIR/input/credentials.json"
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = 'Authenticating with GIPS...' ]
    [ "${lines[1]}" = 'Failed to set UAA target' ]
}

@test "fails to get uaa client token" {
    mock_set_status "${mock_uaa}" 1 2
    run ./teardown.sh coolinstallation1234 "$BATS_TMPDIR/input/credentials.json"
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = 'Authenticating with GIPS...' ]
    [ "${lines[1]}" = 'Failed to get UAA client token' ]
}

@test "fails to get uaa access token" {
    mock_set_status "${mock_uaa}" 1 3
    run ./teardown.sh coolinstallation1234 "$BATS_TMPDIR/input/credentials.json"
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = 'Authenticating with GIPS...' ]
    [ "${lines[1]}" = 'Failed to get UAA access token' ]
}

@test "fails to submit deletion request" {
    cat ./test/fixtures/uaa-context.json | mock_set_output "${mock_uaa}" - 3
    mock_set_status "${mock_curl}" 1 1
    run ./teardown.sh coolinstallation1234 "$BATS_TMPDIR/input/credentials.json"
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = 'Authenticating with GIPS...' ]
    [ "${lines[1]}" = 'Submitting environment deletion request...' ]
    [ "${lines[2]}" = 'Failed to submit deletion request' ]
}

@test "fails to get deletion status" {
    cat ./test/fixtures/uaa-context.json | mock_set_output "${mock_uaa}" - 3
    mock_set_status "${mock_curl}" 1 2
    run ./teardown.sh coolinstallation1234 "$BATS_TMPDIR/input/credentials.json"
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = 'Authenticating with GIPS...' ]
    [ "${lines[1]}" = 'Submitting environment deletion request...' ]
    [ "${lines[2]}" = "Environment is being deleted \"coolinstallation1234\"" ]
    [ "${lines[3]}" = 'Failed to get deletion status' ]
}

@test "fails to get deletion status after checking again" {
    cat ./test/fixtures/uaa-context.json | mock_set_output "${mock_uaa}" - 3
    mock_set_output "${mock_curl}" '{"name": "coolinstallation1234", "paver_job_status": "queued"}' 2
    mock_set_status "${mock_curl}" 1 3
    run ./teardown.sh coolinstallation1234 "$BATS_TMPDIR/input/credentials.json"
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = 'Authenticating with GIPS...' ]
    [ "${lines[1]}" = 'Submitting environment deletion request...' ]
    [ "${lines[2]}" = "Environment is being deleted \"coolinstallation1234\"." ]
    [ "${lines[3]}" = 'Failed to get deletion status' ]
}

@test "installation deletion fails" {
    cat ./test/fixtures/uaa-context.json | mock_set_output "${mock_uaa}" - 3
    mock_set_output "${mock_curl}" '{"name": "coolinstallation1234", "paver_job_status": "failed"}' 2
    run ./teardown.sh coolinstallation1234 "$BATS_TMPDIR/input/credentials.json"
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = 'Authenticating with GIPS...' ]
    [ "${lines[1]}" = 'Submitting environment deletion request...' ]
    [ "${lines[2]}" = "Environment is being deleted \"coolinstallation1234\"" ]
    [ "${lines[3]}" = 'Environment deletion failed:' ]
    [ "${lines[4]}" = '{"name": "coolinstallation1234", "paver_job_status": "failed"}' ]
}

@test "creates a deletion request, waits for it to finish" {
    cat ./test/fixtures/uaa-context.json | mock_set_output "${mock_uaa}" - 3
    mock_set_output "${mock_curl}" '{"name": "coolinstallation1234", "paver_job_status": "queued"}' 2
    mock_set_output "${mock_curl}" '{"name": "coolinstallation1234", "paver_job_status": "deleting"}' 3
    mock_set_output "${mock_curl}" 'curl: (22) The requested URL returned error: 404 Not Found' 4
    mock_set_status "${mock_curl}" 22 4

    run ./teardown.sh coolinstallation1234 "$BATS_TMPDIR/input/credentials.json"
    [ "$status" -eq 0 ]

    # fetches a token from the uaa provided
    [ "$(mock_get_call_args ${mock_uaa} 1)" == "target gips-prod.login.run.pivotal.io" ]
    [ "$(mock_get_call_args ${mock_uaa} 2)" == "get-client-credentials-token pete -s super-secret-1" ]
    [ "$(mock_get_call_args ${mock_uaa} 3)" == "context pete" ]

    # makes the request with curl
    [ "$(mock_get_call_args ${mock_curl} 1 | grep -c "Authorization: Bearer eyJWT9a")" -eq 1 ]
    [ "$(mock_get_call_args ${mock_curl} 1 | grep -c "https://podium.tls.cfapps.io/v1/installs/coolinstallation1234")" -eq 1 ]
    [ "$(mock_get_call_args ${mock_curl} 1 | grep -c "\-X DELETE")" -eq 1 ]

    [ "$(mock_get_call_num ${mock_curl})" = "4" ]
    [ "$(mock_get_call_args ${mock_curl} 2 | grep -c "https://podium.tls.cfapps.io/v1/installs/coolinstallation1234")" -eq 1 ]
    [ "$(mock_get_call_num ${mock_sleep})" = "2" ]
    [ "$(mock_get_call_args ${mock_sleep} 1)" -eq 60 ]
    [ "$(mock_get_call_args ${mock_sleep} 2)" -eq 60 ]

    [ "${lines[0]}" = 'Authenticating with GIPS...' ]
    [ "${lines[1]}" = 'Submitting environment deletion request...' ]
    [ "${lines[2]}" = "Environment is being deleted \"coolinstallation1234\".." ]
    [ "${lines[3]}" = 'Environment deleted!' ]
}

@test "uses an alternative gips address if provided" {
    cat ./test/fixtures/uaa-context.json | mock_set_output "${mock_uaa}" - 3
    mock_set_output "${mock_curl}" '{
        "name": "coolinstallation1234",
        "paver_job_status": "complete",
        "paver_paving_output": {
            "details": "important"
        }
    }'
    mock_set_output "${mock_curl}" 'curl: (22) The requested URL returned error: 404 Not Found' 2
    mock_set_status "${mock_curl}" 22 2
    run ./teardown.sh coolinstallation1234 "$BATS_TMPDIR/input/credentials.json" "podium2.example.com"
    [ "$(mock_get_call_args ${mock_curl} 1 | grep -c "https://podium2.example.com/v1/installs/coolinstallation1234")" -eq 1 ]
    [ "$status" -eq 0 ]
}

@test "uses an alternative gips uaa address if provided" {
    cat ./test/fixtures/uaa-context.json | mock_set_output "${mock_uaa}" - 3
    mock_set_output "${mock_curl}" '{
        "name": "coolinstallation1234",
        "paver_job_status": "complete",
        "paver_paving_output": {
            "details": "important"
        }
    }'
    mock_set_output "${mock_curl}" 'curl: (22) The requested URL returned error: 404 Not Found' 2
    mock_set_status "${mock_curl}" 22 2
    run ./teardown.sh coolinstallation1234 "$BATS_TMPDIR/input/credentials.json" "podium2.example.com" "myuaa.example.net"
    [ "$(mock_get_call_args ${mock_uaa} 1)" == "target myuaa.example.net" ]
    [ "$status" -eq 0 ]
}
