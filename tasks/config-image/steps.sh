#!/bin/bash
# shellcheck source=../../tools/setup_om.sh

function needs_check {
    mrlog section-start --name="checking task needs"

    needs check
    result=$?
    mrlog section-end --name="checking task needs" --result=${result}

    if [[ $result -ne 0 ]] ; then
        echo "Needs check indicated that the task is not ready to execute" >&2
    fi
    return $result
}

function configure_director {
    mrlog section-start --name="configuring BOSH director"

    . setup_om.sh /input/environment.json /input/credentials.json

    # Set up IDP
    om configure-authentication --decryption-passphrase "${OM_PASSWORD}"

    # Configure the director
    build_configure_bosh_json.sh /input/environment.json /input/credentials.json > /tmp/director-config.json
    om configure-director --config /tmp/director-config.json

    result=$?
    mrlog section-end --name="configuring BOSH director" --result=${result}

    if [[ $result -ne 0 ]] ; then
        echo "An error occurred when configuring the BOSH director" >&2
    fi
    return $result
}

function download_srt {
    if [[ "${SKIP_TILE_UPLOAD}" = "true" ]] ; then
        return 0
    fi

    mrlog section-start --name="downloading PAS SRT"
    marman download-srt --version "${PRODUCT_VERSION}"
    result=$?
    mrlog section-end --name="downloading PAS SRT" --result=${result}

    if [[ $result -ne 0 ]] ; then
        echo "An error occurred when downloading PAS SRT" >&2
    fi
    return $result
}

function upload_srt {
    if [[ "${SKIP_TILE_UPLOAD}" = "true" ]] ; then
        return 0
    fi
    . setup_om.sh /input/environment.json /input/credentials.json

    mrlog section-start --name="uploading PAS SRT"
    om upload-product --product ./*.pivotal
    result=$?

    if [[ result -eq 0 ]] ; then
        om stage-product --product-name cf --product-version "${PRODUCT_VERSION}"
        result=$?
    fi

    mrlog section-end --name="uploading PAS SRT" --result=${result}

    if [[ $result -ne 0 ]] ; then
        echo "An error occurred when uploading PAS SRT" >&2
    fi
    return $result

}

function configure_srt {
    mrlog section-start --name="configurure PAS SRT"

    . setup_om.sh /input/environment.json /input/credentials.json

    iaas=$(jq -r '.iaas' /input/environment.json)
    build_configure_product_json.sh /input/environment.json "elastic-runtime.srt.${iaas}.json" "$PCF_VERSION" "$PRODUCT_VERSION" > /tmp/product-config.json
    jq '. + {"resource-config": .resource_config} | del(.resource_config) + {"network-properties": .network} | del(.network) + {"product-properties": .properties} | del(.properties)' /tmp/product-config.json > /tmp/product-config-new-schema.json
    om configure-product --config /tmp/product-config-new-schema.json --ops-file add-cf.yml

    if [ "${iaas}" = "gcp" ] ; then
        upload_and_assign_stemcells.sh google
    else
        upload_and_assign_stemcells.sh "${iaas}"
    fi

    # Deploy
    if [[ "${SKIP_APPLY_CHANGES}" != "true" ]] ; then
        om apply-changes
    fi
    result=$?
    mrlog section-end --name="configurure PAS SRT" --result=${result}

    if [[ $result -ne 0 ]] ; then
        echo "An error occurred when configuring PAS SRT" >&2
    fi
    return $result
}