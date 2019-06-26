#!/usr/bin/env bats

@test "displays usage when no parameters provided" {
    run ./om-helper.sh
    [ "$output" = "usage: om-helper.sh stemcell-assignments [--unmet]" ]
}

@test "displays usage when unknown paraeters provided" {
    run ./om-helper.sh unknown
    [ "$output" = "usage: om-helper.sh stemcell-assignments [--unmet]" ]
}