load test-helpers

setup() {
    export mock_marman="$(mock_bin marman)"
    export mock_om="$(mock_bin om)"
    export mock_om_helper="$(mock_bin om-helper.sh)"
    export PATH="${BIN_MOCKS}:${PATH}"
    export PIVNET_TOKEN="secrets!"
}

teardown() {
    rm -rf "./stemcells"
    clean_bin_mocks
}

@test "shows missing iaas when called with no parameters" {
    run ./upload_and_assign_stemcells.sh
    status_equals 1
    output_says "no iaas provided"
}

@test "exits if om-helper fails" {
    mock_set_status "${mock_om_helper}" 1
    run ./upload_and_assign_stemcells.sh pete-as-a-service
    status_equals 1
    output_says "Failed to get the list of unmet stemcells from OpsManager"
}

@test "does nothing when there are no unmet stemcells" {
    mock_set_output "${mock_om_helper}" '[]'
    unset PIVNET_TOKEN
    run ./upload_and_assign_stemcells.sh pete-as-a-service
    status_equals 0
    output_says "No stemcells need to be uploaded"
}

@test "exits if no PIVNET_TOKEN was defined" {
    mock_set_output "${mock_om_helper}" '[{"product":"my-tile-abcd","os":"ubuntu-xenial","version":"250.63","unmet":true},{"product":"my-tile-abcd","os":"ubuntu-xenial","version":"250.123","unmet":true}]'
    unset PIVNET_TOKEN
    run ./upload_and_assign_stemcells.sh pete-as-a-service
    status_equals 1
    output_says "This test requires stemcells to be downloaded from the Pivotal Network, but no PIVNET_TOKEN was given."
    output_says "Please, re-run this test with a PIVNET_TOKEN defined."
}

@test "correctly calls marman and om for each unmet stemcell" {
    mock_set_output "${mock_om_helper}" '[{"product":"my-tile-abcd","os":"ubuntu-xenial","version":"250.63","unmet":true},{"product":"my-tile-abcd","os":"ubuntu-xenial","version":"250.123","unmet":true}]'
    mock_set_side_effect "${mock_marman}" '
    num=0
    while [ -e "stemcell-${num}.tgz" ] ; do
        num=$((num+1))
    done
    touch "stemcell-${num}.tgz"
    '

    run ./upload_and_assign_stemcells.sh pete-as-a-service
    status_equals 0
    output_says "Downloading stemcell ubuntu-xenial 250.63 for pete-as-a-service from pivnet..."
    output_says "Downloading stemcell ubuntu-xenial 250.123 for pete-as-a-service from pivnet..."
    output_says "Uploading stemcells/stemcell-0.tgz to OpsManager..."
    output_says "Uploading stemcells/stemcell-1.tgz to OpsManager..."

    [ "$(mock_get_call_num "${mock_marman}")" = "2" ]
    [ "$(mock_get_call_args "${mock_marman}" 1)" = "download-stemcell --os ubuntu-xenial --version 250.63 --iaas pete-as-a-service" ]
    [ "$(mock_get_call_args "${mock_marman}" 2)" = "download-stemcell --os ubuntu-xenial --version 250.123 --iaas pete-as-a-service" ]

    [ -e "stemcells/stemcell-0.tgz" ]
    [ -e "stemcells/stemcell-1.tgz" ]

    [ "$(mock_get_call_num "${mock_om}")" = "2" ]
    [ "$(mock_get_call_args "${mock_om}" 1)" = "upload-stemcell -s stemcells/stemcell-0.tgz" ]
    [ "$(mock_get_call_args "${mock_om}" 2)" = "upload-stemcell -s stemcells/stemcell-1.tgz" ]
}

@test "exits if marman download-stemcell fails" {
    mock_set_status "${mock_marman}" 1
    mock_set_output "${mock_om_helper}" '[{"product":"my-tile-abcd","os":"ubuntu-xenial","version":"250.63","unmet":true},{"product":"my-tile-abcd","os":"ubuntu-xenial","version":"250.123","unmet":true}]'
    run ./upload_and_assign_stemcells.sh pete-as-a-service
    status_equals 1
    output_says "Downloading stemcell ubuntu-xenial 250.63 for pete-as-a-service from pivnet..."
    output_says "Failed to download stemcell"
}

@test "exits if om upload-stemcell fails" {
    mock_set_status "${mock_om}" 1
    mock_set_output "${mock_om_helper}" '[{"product":"my-tile-abcd","os":"ubuntu-xenial","version":"250.63","unmet":true},{"product":"my-tile-abcd","os":"ubuntu-xenial","version":"250.123","unmet":true}]'
    run ./upload_and_assign_stemcells.sh pete-as-a-service
    status_equals 1
    output_says "Failed to upload stemcell"
}