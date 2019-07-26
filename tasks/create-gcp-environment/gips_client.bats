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

    mkdir -p "$BATS_TMPDIR/uaac-calls"
    cat > "$BATS_TMPDIR/bin/uaac" <<'EOF'
#!/usr/bin/env bash
call=0
while [ -e "$BATS_TMPDIR/uaac-calls/${call}" ] ; do
    call=$((call+1))
done
echo -n "$@" > "$BATS_TMPDIR/uaac-calls/${call}"

echo "${UAAC_OUTPUT}"

exit ${MOCK_UAAC_RETURN_CODE:-0}
EOF

    mkdir -p "$BATS_TMPDIR/curl-calls"
    cat > "$BATS_TMPDIR/bin/curl" <<'EOF'
#!/usr/bin/env bash
call=0
while [ -e "$BATS_TMPDIR/curl-calls/${call}" ] ; do
    call=$((call+1))
done
echo -n "$@" > "$BATS_TMPDIR/curl-calls/${call}"

exit ${MOCK_CURL_RETURN_CODE:-0}
EOF

    chmod a+x "$BATS_TMPDIR/bin"/*
    export PATH="$BATS_TMPDIR/bin:${PATH}"
}

teardown() {
    rm -rf "$BATS_TMPDIR/input"
    rm -rf "$BATS_TMPDIR/bin"
    rm -rf "$BATS_TMPDIR/uaac-calls"
    rm -rf "$BATS_TMPDIR/curl-calls"
    unset MOCK_UAAC_RETURN_CODE
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
    [ -e "$BATS_TMPDIR/uaac-calls/0" ]
    [ "$(cat "$BATS_TMPDIR/uaac-calls/0")" = 'target uaa.podium.tls.cfapps.io' ]
    [ -e "$BATS_TMPDIR/uaac-calls/1" ]
    [ "$(cat "$BATS_TMPDIR/uaac-calls/1")" = 'token client get pete -s super-secret-1' ]
}

@test "passes the token to curl" {
    export UAAC_OUTPUT="$(cat ./test/fixtures/uaac-context.txt)"

    run ./gips_client.sh "uaa.podium.tls.cfapps.io" "$BATS_TMPDIR/input/credentials.json"
    [ "$status" -eq 0 ]
    [ -e "$BATS_TMPDIR/curl-calls/0" ]
    [ "$(grep -c "Authorization: eyJWT9a" "$BATS_TMPDIR/curl-calls/0")" -eq 1 ]
}

@test "creates a request to install" {
    export UAAC_OUTPUT="$(cat ./test/fixtures/uaac-context.txt)"

    run ./gips_client.sh "uaa.podium.tls.cfapps.io" "$BATS_TMPDIR/input/credentials.json"

    [ $(grep -c "Authorization: eyJWT9a" "$BATS_TMPDIR/curl-calls/0") -eq 1 ]
    [ $(grep -c "\-X POST" "$BATS_TMPDIR/curl-calls/0") -eq 1 ]
    [ $(grep -c "https://podium.tls.cfapps.io/v1/installs" "$BATS_TMPDIR/curl-calls/0") -eq 1 ]
    [ $(grep -c "service_account_key" "$BATS_TMPDIR/curl-calls/0") -eq 3 ]
}

@test "sleeps for 60 seconds when checking the status of the environment" {
    export UAAC_OUTPUT="$(cat ./test/fixtures/uaac-context.txt)"

    run ./gips_client.sh "uaa.podium.tls.cfapps.io" "$BATS_TMPDIR/input/credentials.json"

    [ "$(grep -c "Authorization: eyJWT9a" "$BATS_TMPDIR/curl-calls/0")" -eq 1 ]
}

@test "writes the environment.json file to the output directory" {
    export UAAC_OUTPUT="$(cat ./test/fixtures/uaac-context.txt)"

    run ./gips_client.sh "uaa.podium.tls.cfapps.io" "$BATS_TMPDIR/input/credentials.json"

    [ "$(grep -c "Authorization: eyJWT9a" "$BATS_TMPDIR/curl-calls/0")" -eq 1 ]
}
