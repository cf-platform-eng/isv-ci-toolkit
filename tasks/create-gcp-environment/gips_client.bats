load ../../tools/test-helpers

setup() {
    mkdir -p "$BATS_TMPDIR/input"
    mkdir -p "$BATS_TMPDIR/output"
    export TASK_OUTPUT="$BATS_TMPDIR/output"
    cat > "$BATS_TMPDIR/input/credentials.json" <<'EOF'
{
    "client_id": "pete",
    "client_secret": "super-secret-1",
    "service_account_key": { "status": "secret", "should-i-tell-anyone": false }
}
EOF

    export mock_curl="$(mock_bin curl)"
    export mock_sleep="$(mock_bin sleep)"
    export mock_uaa="$(mock_bin uaa)"
    export PATH="${BIN_MOCKS}:${PATH}"
    unset PAVER
}

teardown() {
    rm -rf "$BATS_TMPDIR/input"
    rm -rf "$BATS_TMPDIR/output"
    clean_bin_mocks
}

@test "asks for ops manager version if none is provided" {
    run ./gips_client.sh
    status_equals 1
    output_says "No OpsManager version provided"
    output_says "USAGE: gips_client <OpsManager version> <credential file> [<optional OpsManager version>]"
    output_says "    OpsManager version - the vesion of the OpsManager that should be created"
    output_says "    credential file - JSON file containing credentials.  Must include:"
    output_says "        client_id"
    output_says "        client_secret"
    output_says "        service_account_key"
    output_says "    Optional OpsManager version - version of a second opsmanager for upgrade tests (default: none)"
    output_says " "
    output_says "Environment variables:"
    output_says "    GIPS_ADDRESS - target podium instance (default: podium.tls.cfapps.io)"
    output_says "    GIPS_UAA_ADDRESS - override the authentication endpoint for GIPS (default: gips-prod.login.run.pivotal.io)"
    output_says "    PARENT_ZONE - add NS records for pcf environment to this zone (default: isvci)"
    output_says "    DNS_SUFFIX - suffix to add to environment name when creating DNS records (default: env.isv.ci)"
    output_says "    PAVER - which paver to use (default: prod_gcp_mp)"
    output_says "    PIVNET_TOKEN - use this PivNet refresh token for downloading stemcells during paving"
}

@test "asks for a credendials file when only one parameter is provided" {
    run ./gips_client.sh 2.6.2
    status_equals 1
    output_says "No credential file provided"
}

@test "missing credential file" {
    run ./gips_client.sh 2.6.2 "/this/path/does/not/exist"
    status_equals 1
    output_says '"/this/path/does/not/exist" was not found'
}

@test "invalid credential file" {
    echo "this is not valid json" > "$BATS_TMPDIR/input/credentials.json"
    run ./gips_client.sh 2.6.2 "$BATS_TMPDIR/input/credentials.json"
    status_equals 1
    output_says "\"$BATS_TMPDIR/input/credentials.json\" is not valid JSON"
}

@test "credential file missing important fields" {
    echo '' > "$BATS_TMPDIR/input/credentials.json"
    run ./gips_client.sh 2.6.2 "$BATS_TMPDIR/input/credentials.json"
    status_equals 1
    output_says 'Credential file missing "client_id"'

    echo '{}' > "$BATS_TMPDIR/input/credentials.json"
    run ./gips_client.sh 2.6.2 "$BATS_TMPDIR/input/credentials.json"
    status_equals 1
    output_says 'Credential file missing "client_id"'

    echo '{"client_id": "pete"}' > "$BATS_TMPDIR/input/credentials.json"
    run ./gips_client.sh 2.6.2 "$BATS_TMPDIR/input/credentials.json"
    status_equals 1
    output_says 'Credential file missing "client_secret"'

    echo '{"client_id": "pete", "client_secret": "shhh"}' > "$BATS_TMPDIR/input/credentials.json"
    run ./gips_client.sh 2.6.2 "$BATS_TMPDIR/input/credentials.json"
    status_equals 1
    output_says 'Credential file missing "service_account_key"'
}

@test "fails to set uaac target" {
    mock_set_status "${mock_uaa}" 1 1
    run ./gips_client.sh 2.6.2 "$BATS_TMPDIR/input/credentials.json"
    status_equals 1
    output_says 'Authenticating with GIPS...'
    output_says 'Failed to set UAA target'
}

@test "fails to get uaac client token" {
    mock_set_status "${mock_uaa}" 1 2
    run ./gips_client.sh 2.6.2 "$BATS_TMPDIR/input/credentials.json"
    status_equals 1
    output_says 'Authenticating with GIPS...'
    output_says 'Failed to get UAA client token'
}

@test "fails to get uaac access token" {
    mock_set_status "${mock_uaa}" 1 3
    run ./gips_client.sh 2.6.2 "$BATS_TMPDIR/input/credentials.json"
    status_equals 1
    output_says 'Authenticating with GIPS...'
    output_says 'Failed to get UAA access token'
}

@test "fails to get the list of pavers" {
    cat ./test/fixtures/uaa-context.json | mock_set_output "${mock_uaa}" - 3
    mock_set_status "${mock_curl}" 1 1
    run ./gips_client.sh 2.6.2 "$BATS_TMPDIR/input/credentials.json"
    status_equals 1
    output_says 'Authenticating with GIPS...'
    output_says 'Getting the list of pavers...'
    output_says 'Failed to get the list of pavers'
}

@test "fails to submit installation request" {
    cat ./test/fixtures/uaa-context.json | mock_set_output "${mock_uaa}" - 3
    mock_set_output "${mock_curl}" '[{"name": "prod_gcp_mp"}]' 1
    mock_set_status "${mock_curl}" 1 2
    run ./gips_client.sh 2.6.2 "$BATS_TMPDIR/input/credentials.json"
    status_equals 1
    output_says 'Authenticating with GIPS...'
    output_says 'Getting the list of pavers...'
    output_says 'Submitting environment request...'
    output_says 'Failed to submit installation request'
}

@test "fails to get installation status" {
    cat ./test/fixtures/uaa-context.json | mock_set_output "${mock_uaa}" - 3
    mock_set_output "${mock_curl}" '[{"name": "prod_gcp_mp"}]' 1
    mock_set_output "${mock_curl}" '{"name": "coolinstallation1234"}' 2
    mock_set_status "${mock_curl}" 1 3
    run ./gips_client.sh 2.6.2 "$BATS_TMPDIR/input/credentials.json"
    status_equals 1
    output_says 'Authenticating with GIPS...'
    output_says 'Getting the list of pavers...'
    output_says 'Submitting environment request...'
    output_says "Environment is being created \"coolinstallation1234\""
    output_says 'Failed to get installation status'
}

@test "fails to get installation status after checking again" {
    cat ./test/fixtures/uaa-context.json | mock_set_output "${mock_uaa}" - 3
    mock_set_output "${mock_curl}" '[{"name": "prod_gcp_mp"}]' 1
    mock_set_output "${mock_curl}" '{"name": "coolinstallation1234"}' 2
    mock_set_output "${mock_curl}" '{"name": "coolinstallation1234", "paver_job_status": "queued"}' 3
    mock_set_status "${mock_curl}" 1 4
    run ./gips_client.sh 2.6.2 "$BATS_TMPDIR/input/credentials.json"
    status_equals 1
    output_says 'Authenticating with GIPS...'
    output_says 'Getting the list of pavers...'
    output_says 'Submitting environment request...'
    output_says "Environment is being created \"coolinstallation1234\"."
    output_says 'Failed to get installation status'
}

@test "installation creation fails" {
    cat ./test/fixtures/uaa-context.json | mock_set_output "${mock_uaa}" - 3
    mock_set_output "${mock_curl}" '[{"name": "prod_gcp_mp"}]' 1
    mock_set_output "${mock_curl}" '{"name": "coolinstallation1234"}' 2
    mock_set_output "${mock_curl}" '{"name": "coolinstallation1234", "paver_job_status": "failed"}' 3
    run ./gips_client.sh 2.6.2 "$BATS_TMPDIR/input/credentials.json"
    status_equals 1
    output_says 'Authenticating with GIPS...'
    output_says 'Getting the list of pavers...'
    output_says 'Submitting environment request...'
    output_says "Environment is being created \"coolinstallation1234\""
    output_says 'Environment creation failed:'
    output_says '{"name": "coolinstallation1234", "paver_job_status": "failed"}'
}

@test "creates an installation, waits for it to finish and writes the environment.json file to the output directory" {
    cat ./test/fixtures/uaa-context.json | mock_set_output "${mock_uaa}" - 3
    mock_set_output "${mock_curl}" '[{"name": "prod_gcp_mp"}]' 1
    mock_set_output "${mock_curl}" '{"name": "coolinstallation1234"}' 2
    mock_set_output "${mock_curl}" '{"name": "coolinstallation1234", "paver_job_status": "queued"}' 3
    mock_set_output "${mock_curl}" '{"name": "coolinstallation1234", "paver_job_status": "working"}' 4
    mock_set_output "${mock_curl}" '{
        "name": "coolinstallation1234",
        "paver_job_status": "complete",
        "paver_paving_output": {
            "details": "important"
        }
    }' 5

    run ./gips_client.sh 2.6.2 "$BATS_TMPDIR/input/credentials.json"
    status_equals 0

    # fetches a token from the uaa provided
    [ "$(mock_get_call_args ${mock_uaa} 1)" == "target gips-prod.login.run.pivotal.io" ]
    [ "$(mock_get_call_args ${mock_uaa} 2)" == "get-client-credentials-token pete -s super-secret-1" ]
    [ "$(mock_get_call_args ${mock_uaa} 3)" == "context pete" ]

    # makes the request with curl
    [ "$(mock_get_call_args ${mock_curl} 2 | grep -c "Authorization: Bearer eyJWT9a")" -eq 1 ]
    [ "$(mock_get_call_args ${mock_curl} 2 | grep -c "https://podium.tls.cfapps.io/v1/installs")" -eq 1 ]
    [ "$(mock_get_call_args ${mock_curl} 2 | grep -c '"opsman_version": "2.6.2",')" -eq 1 ]
    [ "$(mock_get_call_args ${mock_curl} 2 | grep -c '"service_account_key": {')" -eq 2 ]
    [ "$(mock_get_call_args ${mock_curl} 2 | grep -c '"should-i-tell-anyone": false')" -eq 2 ]

    [ "$(mock_get_call_num ${mock_curl})" = "5" ]
    [ "$(mock_get_call_args ${mock_curl} 3 | grep -c "https://podium.tls.cfapps.io/v1/installs/coolinstallation1234")" -eq 1 ]
    [ "$(mock_get_call_num ${mock_sleep})" = "2" ]
    [ "$(mock_get_call_args ${mock_sleep} 1)" -eq 60 ]
    [ "$(mock_get_call_args ${mock_sleep} 2)" -eq 60 ]

    output_says 'Authenticating with GIPS...'
    output_says 'Getting the list of pavers...'
    output_says 'Submitting environment request...'
    output_says "Environment is being created \"coolinstallation1234\".."
    output_says "Environment created!"

    # environment file exists in the output
    [ -f "${TASK_OUTPUT}/environment.json" ]
    [ "$(jq -r ".paver_paving_output.details" "${TASK_OUTPUT}/environment.json")" = "important" ]
}

@test "uses an alternative gips address if provided" {
    cat ./test/fixtures/uaa-context.json | mock_set_output "${mock_uaa}" - 3
    mock_set_output "${mock_curl}" '[{"name": "prod_gcp_mp"}]' 1
    mock_set_output "${mock_curl}" '{
        "name": "coolinstallation1234",
        "paver_job_status": "complete",
        "paver_paving_output": {
            "details": "important"
        }
    }' 2

    export GIPS_ADDRESS="podium2.example.com"
    export GIPS_UAA_ADDRESS="myuaa.example.net"

    run ./gips_client.sh 2.6.2 "$BATS_TMPDIR/input/credentials.json" "podium2.example.com"
    [ "$(mock_get_call_args ${mock_curl} 2 | grep -c "https://podium2.example.com/v1/installs")" -eq 1 ]
    status_equals 0
}

@test "uses an alternative gips uaa address if provided" {
    cat ./test/fixtures/uaa-context.json | mock_set_output "${mock_uaa}" - 3
    mock_set_output "${mock_curl}" '[{"name": "prod_gcp_mp"}]' 1
    mock_set_output "${mock_curl}" '{
        "name": "coolinstallation1234",
        "paver_job_status": "complete",
        "paver_paving_output": {
            "details": "important"
        }
    }' 2

    export GIPS_ADDRESS="podium2.example.com"
    export GIPS_UAA_ADDRESS="myuaa.example.net"

    run ./gips_client.sh 2.6.2 "$BATS_TMPDIR/input/credentials.json"
    [ "$(mock_get_call_args ${mock_uaa} 1)" == "target myuaa.example.net" ]
    status_equals 0
}

@test "uses an alternative paver if provided" {
    cat ./test/fixtures/uaa-context.json | mock_set_output "${mock_uaa}" - 3
    mock_set_output "${mock_curl}" '[{"name": "my-alternative-paver"}]' 1
    mock_set_output "${mock_curl}" '{"name": "coolinstallation1234"}' 2
    mock_set_output "${mock_curl}" '{
        "name": "coolinstallation1234",
        "paver_job_status": "complete",
        "paver_paving_output": {
            "details": "important"
        }
    }' 3

    export PAVER="my-alternative-paver"
    run ./gips_client.sh 2.6.2 "$BATS_TMPDIR/input/credentials.json"

    [ "$(mock_get_call_args ${mock_curl} 2 | grep -c '"paver_name": "my-alternative-paver"')" -eq 1 ]
    status_equals 0
}

@test "fails if paver is not available" {
    cat ./test/fixtures/uaa-context.json | mock_set_output "${mock_uaa}" - 3
    mock_set_output "${mock_curl}" '[{"name": "prod_gcp_mp"}]'

    export PAVER="invalid-paver"
    run  ./gips_client.sh 2.6.2 "$BATS_TMPDIR/input/credentials.json"

    status_equals 1
    output_says 'Getting the list of pavers...'
    output_says 'Not able to use this paver: invalid-paver'
    output_says 'Available pavers are:'
    output_says '  prod_gcp_mp'
}

@test "uses an alternative PivNet token if provided" {
    cat ./test/fixtures/uaa-context.json | mock_set_output "${mock_uaa}" - 3
    mock_set_output "${mock_curl}" '[{"name": "prod_gcp_mp"}]' 1
    mock_set_output "${mock_curl}" '{"name": "coolinstallation1234"}' 2
    mock_set_output "${mock_curl}" '{
        "name": "coolinstallation1234",
        "paver_job_status": "complete",
        "paver_paving_output": {
            "details": "important"
        }
    }' 3

    export PIVNET_TOKEN="my-pivnet-refresh-token"
    run ./gips_client.sh 2.6.2 "$BATS_TMPDIR/input/credentials.json"

    [ "$(mock_get_call_args ${mock_curl} 2 | grep -c '"pivnet_refresh_token": "my-pivnet-refresh-token"')" -eq 1 ]
    status_equals 0
}