#!/bin/bash

# Test Jenkins requests for metadata gets redirected to correct version of update center.

UPDATE_CENTER='https://updates.jenkins-ci.org/'

result=0

function checkRedirect() {
  version="$1"
  target="$2"
  stderr="$(curl -vIL "${UPDATE_CENTER}/update-center.json?id=default&version=${version}" 2>&1 > /dev/null)"
  header="$(grep 'Location' <<< "$stderr" | tr -d '\r')"
  #target="$( sed 's~.*/\([^/]*\)/update-center.json~\1~' <<< "$header")"

  expected="Location: ${UPDATE_CENTER}${target}/update-center.json"
  if [[ "$header" != *"$expected" ]]; then
    echo >&2 "Not redirected to correct update center for ${version}"
    echo >&2 "  Expected: $expected"
    if [ -z "$header" ]; then
      echo >&2 "    Actual: $stderr"
    else
      echo >&2 "    Actual: $header"
    fi
    result=1
  fi
}

checkRedirect "2.46" "2.46"
checkRedirect "2.46.1" "stable-2.46"
checkRedirect "2.46.3" "stable-2.46"
checkRedirect "2.46.3.1" "stable-2.46"
checkRedirect "2.46.3-SNAPSHOT (someone built this now)" "stable-2.46"
checkRedirect "2.46.3-1234567" "stable-2.46"

exit $result
