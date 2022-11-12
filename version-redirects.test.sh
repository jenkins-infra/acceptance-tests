#!/bin/bash

# Test Jenkins requests for metadata gets redirected to correct version of update center.

UPDATE_CENTER='https://updates.jenkins.io/'

result=0

function checkRedirect() {
  version="$1"
  target="$2"
  echo ====== $version $target ======
  stderr="$(curl -vIL "${UPDATE_CENTER}/update-center.json?id=default&version=${version}" 2>&1 > /dev/null)"
  header="$(grep -i 'location:' <<< "$stderr" | tr -d '\r')"
  #target="$( sed 's~.*/\([^/]*\)/update-center.json~\1~' <<< "$header")"

  expected="< location: ${UPDATE_CENTER}${target}/update-center.json"
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

checkRedirect "2.303.3"          "dynamic-stable-2.303.3"

checkRedirect "2.319.1.1"        "current"                # Unrecognized version takes current
checkRedirect "2.319.1-SNAPSHOT" "dynamic-stable-2.319.1"
checkRedirect "2.319.1-12345678" "dynamic-stable-2.319.1"
checkRedirect "2.319.1"          "dynamic-stable-2.319.1"
checkRedirect "2.319.3"          "dynamic-stable-2.319.3"

checkRedirect "2.332.1"          "dynamic-stable-2.332.1"
checkRedirect "2.332.2"          "dynamic-stable-2.332.2"
checkRedirect "2.332.3"          "dynamic-stable-2.332.3"

checkRedirect "2.350"            "dynamic-2.350"
checkRedirect "2.361"            "dynamic-2.361"

exit $result
