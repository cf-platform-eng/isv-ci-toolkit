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