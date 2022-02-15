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

checkRedirect "2.277"            "dynamic-2.277"

checkRedirect "2.277.1"          "dynamic-stable-2.277.1"
checkRedirect "2.277.2"          "dynamic-stable-2.277.2"
checkRedirect "2.277.3"          "dynamic-stable-2.277.3"

checkRedirect "2.289"            "dynamic-2.289"

checkRedirect "2.289.1"          "dynamic-stable-2.289.1"

checkRedirect "2.303.1.1"        "current"                # Unrecognized version takes current
checkRedirect "2.303.1-SNAPSHOT" "dynamic-stable-2.303.1"
checkRedirect "2.303.1-12345678" "dynamic-stable-2.303.1"
checkRedirect "2.303.1"          "dynamic-stable-2.303.1"
checkRedirect "2.303.2"          "dynamic-stable-2.303.2"
checkRedirect "2.303.3"          "dynamic-stable-2.303.3"

exit $result
