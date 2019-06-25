#/bin/bash
set +x # Hide secrets

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && echo -e "You must source this script\nsource ${0}" && exit 1


run() {
    export OM_PASSWORD=$(cat ${configjson} | jq -r .ops_manager.password)
    export OM_TARGET=$(cat ${configjson} | jq -r .ops_manager.url)
    export OM_USERNAME=$(cat ${configjson} | jq -r .ops_manager.username)
}

configjson=$1
if [[ -z "${configjson}" ]] ; then
    echo "USAGE: $0 <config json file>"
    echo "  config json file: Environment config file from toolsmiths"
else
    run
fi

