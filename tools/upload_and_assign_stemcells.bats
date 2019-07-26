load test-helpers

setup() {
    export mock_marman="$(mock_bin marman)"
    export mock_om="$(mock_bin om)"
    export mock_om_helper="$(mock_bin om-helper.sh)"
    export PATH="${BIN_MOCKS}:${PATH}"
}

teardown() {
    rm -rf "./stemcells"
    clean_bin_mocks
}

@test "shows missing iaas when called with no parameters" {
    run ./upload_and_assign_stemcells.sh
    [ "$status" -eq 1 ]
    [ "$output" = "no iaas provided" ]
}

@test "exits if om-helper fails" {
    mock_set_status "${mock_om_helper}" 1
    run ./upload_and_assign_stemcells.sh pete-as-a-service
    [ "$status" -eq 1 ]
    [ "$output" = "Failed to get the list of unmet stemcells from OpsManager" ]
}

@test "does nothing when there are no unmet stemcells" {
    mock_set_output "${mock_om_helper}" '[]'
    run ./upload_and_assign_stemcells.sh pete-as-a-service
    [ "$status" -eq 0 ]
    [ "$output" = "No stemcells need to be uploaded" ]
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
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "Downloading stemcell ubuntu-xenial 250.63 for pete-as-a-service from pivnet..." ]
    [ "${lines[1]}" = "Downloading stemcell ubuntu-xenial 250.123 for pete-as-a-service from pivnet..." ]
    [ "${lines[2]}" = "Uploading stemcells/stemcell-0.tgz to OpsManager..." ]
    [ "${lines[3]}" = "Uploading stemcells/stemcell-1.tgz to OpsManager..." ]

    [ "$(mock_get_call_num "${mock_marman}")" = "2" ]
    [ "$(mock_get_call_args "${mock_marman}" 1)" = "download-stemcell -o ubuntu-xenial -v 250.63 -i pete-as-a-service" ]
    [ "$(mock_get_call_args "${mock_marman}" 2)" = "download-stemcell -o ubuntu-xenial -v 250.123 -i pete-as-a-service" ]

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
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = "Downloading stemcell ubuntu-xenial 250.63 for pete-as-a-service from pivnet..." ]
    [ "${lines[1]}" = "Failed to download stemcell" ]
}

@test "exits if om upload-stemcell fails" {
    mock_set_status "${mock_om}" 1
    mock_set_output "${mock_om_helper}" '[{"product":"my-tile-abcd","os":"ubuntu-xenial","version":"250.63","unmet":true},{"product":"my-tile-abcd","os":"ubuntu-xenial","version":"250.123","unmet":true}]'
    run ./upload_and_assign_stemcells.sh pete-as-a-service
    [ "$status" -eq 1 ]
    [ "${lines[3]}" = "Failed to upload stemcell" ]
}