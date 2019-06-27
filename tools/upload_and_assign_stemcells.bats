#!/usr/bin/env bats

setup() {
    mkdir -p "$BATS_TMPDIR/bin"
    echo 'echo ${MOCK_OM_HELPER_OUTPUT}; exit ${MOCK_OM_HELPER_RETURN_CODE:-0}' > "$BATS_TMPDIR/bin/om-helper.sh"

    mkdir -p "$BATS_TMPDIR/marman-calls"
    cat > "$BATS_TMPDIR/bin/marman" <<'EOF'
#!/usr/bin/env bash
call=0
while [ -e "$BATS_TMPDIR/marman-calls/${call}" ] ; do
    call=$((call+1))
done
echo -n "$@" > "$BATS_TMPDIR/marman-calls/${call}"
touch "stemcell-${call}.tgz"
exit ${MOCK_MARMAN_RETURN_CODE:-0}
EOF

    mkdir -p "$BATS_TMPDIR/om-calls"
    cat > "$BATS_TMPDIR/bin/om" <<'EOF'
#!/usr/bin/env bash
call=0
while [ -e "$BATS_TMPDIR/om-calls/${call}" ] ; do
    call=$((call+1))
done
echo -n "$@" > "$BATS_TMPDIR/om-calls/${call}"
exit ${MOCK_OM_RETURN_CODE:-0}
EOF

    chmod a+x "$BATS_TMPDIR/bin"/*
    export PATH="$BATS_TMPDIR/bin:${PATH}"
}

teardown() {
    rm -rf "./stemcells"
    rm -rf "$BATS_TMPDIR/bin"
    rm -rf "$BATS_TMPDIR/marman-calls"
    rm -rf "$BATS_TMPDIR/om-calls"
    unset MOCK_OM_HELPER_OUTPUT
    unset MOCK_OM_HELPER_RETURN_CODE
    unset MOCK_MARMAN_RETURN_CODE
    unset MOCK_OM_RETURN_CODE
}

@test "shows missing iaas when called with no parameters" {
    run ./upload_and_assign_stemcells.sh
    [ "$status" -eq 1 ]
    [ "$output" = "no iaas provided" ]
}

@test "exits if om-helper fails" {
    export MOCK_OM_HELPER_RETURN_CODE=1
    run ./upload_and_assign_stemcells.sh pete-as-a-service
    [ "$status" -eq 1 ]
    [ "$output" = "Failed to get the list of unmet stemcells from OpsManager" ]
}

@test "does nothing when there are no unmet stemcells" {
    export MOCK_OM_HELPER_OUTPUT="[]"
    run ./upload_and_assign_stemcells.sh pete-as-a-service
    [ "$status" -eq 0 ]
    [ "$output" = "No stemcells need to be uploaded" ]
}

@test "correctly calls marman and om for each unmet stemcell" {
    export MOCK_OM_HELPER_OUTPUT='[{"product":"my-tile-abcd","os":"ubuntu-xenial","version":"250.63","unmet":true},{"product":"my-tile-abcd","os":"ubuntu-xenial","version":"250.123","unmet":true}]'
    run ./upload_and_assign_stemcells.sh pete-as-a-service
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "Downloading stemcell ubuntu-xenial 250.63 for pete-as-a-service from pivnet..." ]
    [ "${lines[1]}" = "Downloading stemcell ubuntu-xenial 250.123 for pete-as-a-service from pivnet..." ]
    [ "${lines[2]}" = "Uploading stemcells/stemcell-0.tgz to OpsManager..." ]
    [ "${lines[3]}" = "Uploading stemcells/stemcell-1.tgz to OpsManager..." ]

    [ -e "$BATS_TMPDIR/marman-calls/0" ]
    [ "$(cat "$BATS_TMPDIR/marman-calls/0")" = "download-stemcell -o ubuntu-xenial -v 250.63 -i pete-as-a-service" ]
    [ -e "$BATS_TMPDIR/marman-calls/1" ]
    [ "$(cat "$BATS_TMPDIR/marman-calls/1")" = "download-stemcell -o ubuntu-xenial -v 250.123 -i pete-as-a-service" ]

    [ -e "stemcells/stemcell-0.tgz" ]
    [ -e "stemcells/stemcell-1.tgz" ]

    [ -e "$BATS_TMPDIR/om-calls/0" ]
    [ "$(cat "$BATS_TMPDIR/om-calls/0")" = "upload-stemcell -s stemcells/stemcell-0.tgz" ]
    [ -e "$BATS_TMPDIR/om-calls/1" ]
    [ "$(cat "$BATS_TMPDIR/om-calls/1")" = "upload-stemcell -s stemcells/stemcell-1.tgz" ]
}

@test "exits if marman download-stemcell fails" {
    export MOCK_OM_HELPER_OUTPUT='[{"product":"my-tile-abcd","os":"ubuntu-xenial","version":"250.63","unmet":true},{"product":"my-tile-abcd","os":"ubuntu-xenial","version":"250.123","unmet":true}]'
    export MOCK_MARMAN_RETURN_CODE=1
    run ./upload_and_assign_stemcells.sh pete-as-a-service
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = "Downloading stemcell ubuntu-xenial 250.63 for pete-as-a-service from pivnet..." ]
    [ "${lines[1]}" = "Failed to download stemcell" ]
}

@test "exits if om upload-stemcell fails" {
    export MOCK_OM_HELPER_OUTPUT='[{"product":"my-tile-abcd","os":"ubuntu-xenial","version":"250.63","unmet":true},{"product":"my-tile-abcd","os":"ubuntu-xenial","version":"250.123","unmet":true}]'
    export MOCK_OM_RETURN_CODE=1
    run ./upload_and_assign_stemcells.sh pete-as-a-service
    [ "$status" -eq 1 ]
    [ "${lines[3]}" = "Failed to upload stemcell" ]
}