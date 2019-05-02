#!/usr/bin/env bash
set +x # Hide secrets

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && echo -e "You must source this script\nsource ${0}" && exit 1

me="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [[ -z "${SECRETS}" ]]; then  # Not using concourse - local dev version
    echo "Syncing with LastPass"
    if ! lpass sync; then
      echo -e "\n***WARNING***"
      echo "Not logged in to Last Pass, if you're not prompted for"
      echo "your password you will need to use: "
      echo "  lpass login [--trust] your@email.address"
      return
    fi

    echo "Setting secrets"
    eval "$("${me}/yml-to-env.py" <(lpass show --notes 'Shared-CF Platform Engineering/isv-dashboard/pipeline-secrets.json'))"
else
    echo "Setting secrets"
    eval "$("${me}/yml-to-env.py" <(echo "${SECRETS}"))"
fi