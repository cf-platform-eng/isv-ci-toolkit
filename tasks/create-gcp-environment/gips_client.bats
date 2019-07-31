load temp/bats-mock # docs at https://github.com/grayhemp/bats-mock

setup() {
    mkdir -p "$BATS_TMPDIR/input"
    cat > "$BATS_TMPDIR/input/credentials.json" <<'EOF'
{
    "client_id": "pete",
    "client_secret": "super-secret-1",
    "service_account_key": { "status": "secret", "should-i-tell-anyone": false }
}
EOF

    export BATS_TMPDIR
    mkdir -p "$BATS_TMPDIR/bin"

    export mock_curl="$(mock_create)"
    ln -sf "${mock_curl}" "${BATS_TMPDIR}/bin/curl"

    export mock_sleep="$(mock_create)"
    ln -sf "${mock_sleep}" "${BATS_TMPDIR}/bin/sleep"

    export mock_uaac="$(mock_create)"
    ln -sf "${mock_uaac}" "${BATS_TMPDIR}/bin/uaac"

    chmod a+x "$BATS_TMPDIR/bin"/*
    export PATH="$BATS_TMPDIR/bin:${PATH}"
}

teardown() {
    rm -rf "$BATS_TMPDIR/input"
    rm -rf "$BATS_TMPDIR/bin"
    rm -rf ./output
}

@test "asks for ops manager version if none is provided" {
    run ./gips_client.sh
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = "no OpsManager version provided" ]
    [ "${lines[1]}" = "USAGE: gips_client <OpsManager version> <credential file> [<GIPS address>] [<GIPS UAA address>]" ]
    [ "${lines[2]}" = "    OpsManager version - the vesion of the OpsManager that should be created" ]
    [ "${lines[3]}" = "    credential file - JSON file containing credentials.  Must include:" ]
    [ "${lines[4]}" = "        client_id" ]
    [ "${lines[5]}" = "        client_secret" ]
    [ "${lines[6]}" = "        service_account_key" ]
    [ "${lines[7]}" = "    GIPS address - target podium instance (default: podium.tls.cfapps.io)" ]
    [ "${lines[8]}" = "    GIPS UAA address - override the authentication endpoint for GIPS (default: gips-prod.login.run.pivotal.io)" ]
}

@test "asks for a credendials file when only one parameter is provided" {
    run ./gips_client.sh 2.6.2
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = "no credential file provided" ]
}

@test "missing credential file" {
    run ./gips_client.sh 2.6.2 "/this/path/does/not/exist"
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = '"/this/path/does/not/exist" was not found' ]
}

@test "invalid credential file" {
    echo "this is not valid json" > "$BATS_TMPDIR/input/credentials.json"
    run ./gips_client.sh 2.6.2 "$BATS_TMPDIR/input/credentials.json"
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = "\"$BATS_TMPDIR/input/credentials.json\" is not valid JSON" ]
}

@test "credential file missing important fields" {
    echo '' > "$BATS_TMPDIR/input/credentials.json"
    run ./gips_client.sh 2.6.2 "$BATS_TMPDIR/input/credentials.json"
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = 'credential file missing "client_id"' ]

    echo '{}' > "$BATS_TMPDIR/input/credentials.json"
    run ./gips_client.sh 2.6.2 "$BATS_TMPDIR/input/credentials.json"
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = 'credential file missing "client_id"' ]

    echo '{"client_id": "pete"}' > "$BATS_TMPDIR/input/credentials.json"
    run ./gips_client.sh 2.6.2 "$BATS_TMPDIR/input/credentials.json"
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = 'credential file missing "client_secret"' ]

    echo '{"client_id": "pete", "client_secret": "shhh"}' > "$BATS_TMPDIR/input/credentials.json"
    run ./gips_client.sh 2.6.2 "$BATS_TMPDIR/input/credentials.json"
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = 'credential file missing "service_account_key"' ]
}

@test "fails to set uaac target" {
    mock_set_status "${mock_uaac}" 1 1
    run ./gips_client.sh 2.6.2 "$BATS_TMPDIR/input/credentials.json"
    [ "$status" -eq 1 ]
    [ "$output" = 'failed to set UAA target' ]
}

@test "fails to get uaac client token" {
    mock_set_status "${mock_uaac}" 1 2
    run ./gips_client.sh 2.6.2 "$BATS_TMPDIR/input/credentials.json"
    [ "$status" -eq 1 ]
    [ "$output" = 'failed to get UAA client token' ]
}

@test "fails to get uaac access token" {
    mock_set_status "${mock_uaac}" 1 3
    run ./gips_client.sh 2.6.2 "$BATS_TMPDIR/input/credentials.json"
    [ "$status" -eq 1 ]
    [ "$output" = 'failed to get UAA access token' ]
}

@test "fails to submit installation request" {
    cat ./test/fixtures/uaac-context.txt | mock_set_output "${mock_uaac}" - 3
    mock_set_status "${mock_curl}" 1 1
    run ./gips_client.sh 2.6.2 "$BATS_TMPDIR/input/credentials.json"
    [ "$status" -eq 1 ]
    [ "$output" = 'failed to submit installation request' ]
}

@test "fails to get installation status" {
    cat ./test/fixtures/uaac-context.txt | mock_set_output "${mock_uaac}" - 3
    mock_set_status "${mock_curl}" 1 2
    run ./gips_client.sh 2.6.2 "$BATS_TMPDIR/input/credentials.json"
    [ "$status" -eq 1 ]
    [ "$output" = 'failed to get installation status' ]
}

@test "fails to get installation status after checking again" {
    cat ./test/fixtures/uaac-context.txt | mock_set_output "${mock_uaac}" - 3
    mock_set_output "${mock_curl}" '{"name": "coolinstallation1234", "paver_job_status": "queued"}' 2
    mock_set_status "${mock_curl}" 1 3
    run ./gips_client.sh 2.6.2 "$BATS_TMPDIR/input/credentials.json"
    [ "$status" -eq 1 ]
    [ "$output" = 'failed to get installation status' ]
}

@test "installation creation fails" {
    cat ./test/fixtures/uaac-context.txt | mock_set_output "${mock_uaac}" - 3
    mock_set_output "${mock_curl}" '{"name": "coolinstallation1234", "paver_job_status": "failed"}' 2
    run ./gips_client.sh 2.6.2 "$BATS_TMPDIR/input/credentials.json"
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = 'installation failed:' ]
    [ "${lines[1]}" = '{"name": "coolinstallation1234", "paver_job_status": "failed"}' ]
}

@test "creates an installation, waits for it to finish and writes the environment.json file to the output directory" {
    cat ./test/fixtures/uaac-context.txt | mock_set_output "${mock_uaac}" - 3
    mock_set_output "${mock_curl}" '{"name": "coolinstallation1234"}' 1
    mock_set_output "${mock_curl}" '{"name": "coolinstallation1234", "paver_job_status": "queued"}' 2
    mock_set_output "${mock_curl}" '{"name": "coolinstallation1234", "paver_job_status": "working"}' 3
    mock_set_output "${mock_curl}" '{
        "name": "coolinstallation1234",
        "paver_job_status": "complete",
        "paver_paving_output": {
            "details": "important"
        }
    }' 4

    run ./gips_client.sh 2.6.2 "$BATS_TMPDIR/input/credentials.json"
    [ "$status" -eq 0 ]

    # fetches a token from the uaa provided
    [ "$(mock_get_call_args ${mock_uaac} 1)" == "target gips-prod.login.run.pivotal.io" ]
    [ "$(mock_get_call_args ${mock_uaac} 2)" == "token client get pete -s super-secret-1" ]
    [ "$(mock_get_call_args ${mock_uaac} 3)" == "context pete" ]

    # makes the request with curl
    [ "$(mock_get_call_args ${mock_curl} 1 | grep -c "Authorization: Bearer eyJWT9a")" -eq 1 ]
    [ "$(mock_get_call_args ${mock_curl} 1 | grep -c "https://podium.tls.cfapps.io/v1/installs")" -eq 1 ]
    [ "$(mock_get_call_args ${mock_curl} 1 | grep -c '"opsman_version": "2.6.2",')" -eq 1 ]
    [ "$(mock_get_call_args ${mock_curl} 1 | grep -c '"service_account_key": {')" -eq 2 ]
    [ "$(mock_get_call_args ${mock_curl} 1 | grep -c '"should-i-tell-anyone": false')" -eq 2 ]

    [ "$(mock_get_call_num ${mock_curl})" = "4" ]
    [ "$(mock_get_call_args ${mock_curl} 2 | grep -c "https://podium.tls.cfapps.io/v1/installs/coolinstallation1234")" -eq 1 ]
    [ "$(mock_get_call_num ${mock_sleep})" = "2" ]
    [ "$(mock_get_call_args ${mock_sleep} 1)" -eq 60 ]
    [ "$(mock_get_call_args ${mock_sleep} 2)" -eq 60 ]

    # environment file exists in the output
    [ -f ./output/environment.json ]
    [ "$(jq -r ".paver_paving_output.details" ./output/environment.json)" = "important" ]
}

@test "uses an alternative gips address if provided" {
    cat ./test/fixtures/uaac-context.txt | mock_set_output "${mock_uaac}" - 3
    mock_set_output "${mock_curl}" '{
        "name": "coolinstallation1234",
        "paver_job_status": "complete",
        "paver_paving_output": {
            "details": "important"
        }
    }'
    run ./gips_client.sh 2.6.2 "$BATS_TMPDIR/input/credentials.json" "podium2.example.com"
    [ "$(mock_get_call_args ${mock_curl} 1 | grep -c "https://podium2.example.com/v1/installs")" -eq 1 ]
    [ "$status" -eq 0 ]
}

@test "uses an alternative gips uaa address if provided" {
    cat ./test/fixtures/uaac-context.txt | mock_set_output "${mock_uaac}" - 3
    mock_set_output "${mock_curl}" '{
        "name": "coolinstallation1234",
        "paver_job_status": "complete",
        "paver_paving_output": {
            "details": "important"
        }
    }'
    run ./gips_client.sh 2.6.2 "$BATS_TMPDIR/input/credentials.json" "podium2.example.com" "myuaa.example.net"
    [ "$(mock_get_call_args ${mock_uaac} 1)" == "target myuaa.example.net" ]
    [ "$status" -eq 0 ]
}
