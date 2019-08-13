#!/usr/bin/env bash
load temp/bats-mock # docs at https://github.com/grayhemp/bats-mock

BIN_MOCKS="${BATS_TMPDIR}/bin-mocks"


# Echo command that always appears on output without upsetting TAPS compliance
becho() {
    echo -e "# ${1}" >&3
}

mock_bin() {
    mkdir -p "$BIN_MOCKS"

    mock="$(mock_create)"
    ln -sf "${mock}" "${BIN_MOCKS}/${1}"

    echo ${mock}
}

clean_bin_mocks() {
    rm -rf "${BIN_MOCKS}"
}

# usage:
#   output_says "a thing"
#
# Fails if 'a thing' is not in $output/
# it also removes everything in output up to and including the matched string,
# perfect for order checking.
output_says() {
    if [[ "${output}" == *"${1}"* ]]; then
        output="${output#*${1}}"
    else
        echo "# Could not find ${1} in output:" >&2
        echo "${output}" >&2
        return 1
    fi
}

output_equals() {
    if [[ "${output}" != "${1}" ]]; then
        echo "# expected output to equal ${1}, but got ${output}"
        return 1
    fi
}

status_equals() {
    if [[ "${status}" -ne ${1} ]]; then
        echo "# expected status to equal ${1}, but got ${status}"
        return 1
    fi
}
