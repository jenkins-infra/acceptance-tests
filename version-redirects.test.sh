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

checkRedirect "2.375.1"          "dynamic-stable-2.375.1"
checkRedirect "2.375.2"          "dynamic-stable-2.375.2"
checkRedirect "2.375.3"          "dynamic-stable-2.375.3"

checkRedirect "2.387.1.1"        "current"                # Unrecognized version takes current

checkRedirect "2.387.1"          "dynamic-stable-2.387.1"
checkRedirect "2.387.3"          "dynamic-stable-2.387.3"

checkRedirect "2.401.3"          "dynamic-stable-2.401.3"

checkRedirect "2.414.3"          "dynamic-stable-2.414.3"

checkRedirect "2.426.1"          "dynamic-stable-2.426.1"

checkRedirect "2.426"            "dynamic-2.426"
checkRedirect "2.427"            "dynamic-2.427"
checkRedirect "2.428"            "dynamic-2.427"
checkRedirect "2.429"            "dynamic-2.427"
checkRedirect "2.430"            "dynamic-2.427"
checkRedirect "2.431"            "dynamic-2.427"
checkRedirect "2.432"            "dynamic-2.432"
checkRedirect "2.433"            "dynamic-2.432"
checkRedirect "2.434"            "dynamic-2.434"
checkRedirect "2.435"            "dynamic-2.434"

exit $result
