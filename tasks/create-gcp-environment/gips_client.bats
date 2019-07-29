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

@test "asks for gips address if none is provided" {
    run ./gips_client.sh
    [ "$status" -eq 1 ]
    [ "$output" = "no gips uaa address provided" ]
}

@test "asks for a credendials file when only one parameter is provided" {
    run ./gips_client.sh "uaa.podium.tls.cfapps.io"
    [ "$status" -eq 1 ]
    [ "$output" = "no credential file provided" ]
}

@test "runs successfully with the correct files" {
    run ./gips_client.sh "uaa.podium.tls.cfapps.io" "$BATS_TMPDIR/input/credentials.json"
    [ "$status" -eq 0 ]
}

@test "fetches a token from the uaa provided" {
    run ./gips_client.sh "uaa.podium.tls.cfapps.io" "$BATS_TMPDIR/input/credentials.json"
    [ "$status" -eq 0 ]

    [ "$(mock_get_call_args ${mock_uaac} 1)" == "target uaa.podium.tls.cfapps.io" ]
    [ "$(mock_get_call_args ${mock_uaac} 2)" == "token client get pete -s super-secret-1" ]
    [ "$(mock_get_call_args ${mock_uaac} 3)" == "context pete" ]
}

@test "passes the token to curl" {
    cat ./test/fixtures/uaac-context.txt | mock_set_output "${mock_uaac}" - 3

    run ./gips_client.sh "uaa.podium.tls.cfapps.io" "$BATS_TMPDIR/input/credentials.json"
    [ "$status" -eq 0 ]
    [ "$(mock_get_call_args ${mock_curl} 1 | grep -c "Authorization: Bearer eyJWT9a")" -eq 1 ]
}

@test "creates a request to install" {
    cat ./test/fixtures/uaac-context.txt | mock_set_output "${mock_uaac}" - 3

    run ./gips_client.sh "uaa.podium.tls.cfapps.io" "$BATS_TMPDIR/input/credentials.json"

    [ "$(mock_get_call_args ${mock_curl} 1 | grep -c "Authorization: Bearer eyJWT9a")" -eq 1 ]
    [ "$(mock_get_call_args ${mock_curl} 1 | grep -c "https://podium.tls.cfapps.io/v1/installs")" -eq 1 ]
    [ "$(mock_get_call_args ${mock_curl} 1 | grep -c '"service_account_key": {')" -eq 2 ]
    [ "$(mock_get_call_args ${mock_curl} 1 | grep -c '"should-i-tell-anyone": false')" -eq 2 ]
}

@test "sleeps for 60 seconds when checking the status of the environment" {
    cat ./test/fixtures/uaac-context.txt | mock_set_output "${mock_uaac}" - 3
    mock_set_output "${mock_curl}" '{"name": "coolinstallation1234"}' 1
    mock_set_output "${mock_curl}" '{"name": "coolinstallation1234", "paver_job_status": "queued"}' 2
    mock_set_output "${mock_curl}" '{"name": "coolinstallation1234", "paver_job_status": "working"}' 3
    mock_set_output "${mock_curl}" '{"name": "coolinstallation1234", "paver_job_status": "complete"}' 4

    run ./gips_client.sh "uaa.podium.tls.cfapps.io" "$BATS_TMPDIR/input/credentials.json"
    [ "$status" -eq 0 ]
    [ "$(mock_get_call_num ${mock_curl})" = "4" ]
    [ "$(mock_get_call_args ${mock_curl} 2 | grep -c "https://podium.tls.cfapps.io/v1/installs/coolinstallation1234")" -eq 1 ]
    [ "$(mock_get_call_num ${mock_sleep})" = "2" ]
    [ "$(mock_get_call_args ${mock_sleep} 1)" -eq 60 ]
    [ "$(mock_get_call_args ${mock_sleep} 2)" -eq 60 ]
}

@test "writes the environment.json file to the output directory" {
    cat ./test/fixtures/uaac-context.txt | mock_set_output "${mock_uaac}" - 3
    mock_set_output "${mock_curl}" '{
        "name": "coolinstallation1234",
        "paver_job_status": "complete",
        "paver_paving_output": {
            "details": "important"
        }
    }'

    run ./gips_client.sh "uaa.podium.tls.cfapps.io" "$BATS_TMPDIR/input/credentials.json"
    [ "$status" -eq 0 ]
    [ -f ./output/environment.json ]
    [ "$(jq -r ".paver_paving_output.details" ./output/environment.json)" = "important" ]
}
