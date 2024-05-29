#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

function getOptionListForList {
  local option="${1}" list="${2}" resultOptions="" i=""

  for i in $list; do
    if [[ -z "${resultOptions}" ]]; then
      resultOptions+="${option} $i"
    else
      resultOptions+=" ${option} $i"
    fi
  done

  echo "${resultOptions}"
}