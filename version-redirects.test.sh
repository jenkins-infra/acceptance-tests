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

checkRedirect "2.204"            "dynamic-2.204"

checkRedirect "2.204.6"          "dynamic-stable-2.204.6"

checkRedirect "2.204.3.1"        "current"                # Unrecognized version takes current
checkRedirect "2.204.3-SNAPSHOT" "current"
checkRedirect "2.204.3-1234567"  "current"

checkRedirect "2.222"            "dynamic-2.222"

checkRedirect "2.222.4"          "dynamic-stable-2.222.4"

checkRedirect "2.222.3.1"        "current"                # Unrecognized version takes current
checkRedirect "2.222.3-SNAPSHOT" "current"
checkRedirect "2.222.3-1234567"  "current"

checkRedirect "2.235.2"          "dynamic-stable-2.235.2"
checkRedirect "2.235.3"          "dynamic-stable-2.235.3"

checkRedirect "2.235.1.1"        "current"                # Unrecognized version takes current
checkRedirect "2.235.1-SNAPSHOT" "current"
checkRedirect "2.235.1-1234567"  "current"

checkRedirect "2.263.1"          "dynamic-stable-2.263.1"

exit $result
