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

checkRedirect "2.414.1.1"        "current"                # Unrecognized version takes current

checkRedirect "2.414.3"          "dynamic-stable-2.414.3"

checkRedirect "2.426.1"          "dynamic-stable-2.426.1"
checkRedirect "2.426.2"          "dynamic-stable-2.426.2"
checkRedirect "2.426.3"          "dynamic-stable-2.426.3"

checkRedirect "2.440.1"          "dynamic-stable-2.440.1"
checkRedirect "2.440.2"          "dynamic-stable-2.440.2"
checkRedirect "2.440.3"          "dynamic-stable-2.440.3"

checkRedirect "2.443"            "dynamic-2.443"
checkRedirect "2.444"            "dynamic-2.444"
checkRedirect "2.445"            "dynamic-2.444"
checkRedirect "2.446"            "dynamic-2.446"
checkRedirect "2.447"            "dynamic-2.446"
checkRedirect "2.448"            "dynamic-2.446"
checkRedirect "2.449"            "dynamic-2.446"
checkRedirect "2.450"            "dynamic-2.450"
checkRedirect "2.451"            "dynamic-2.450"
checkRedirect "2.452"            "dynamic-2.452"
checkRedirect "2.453"            "dynamic-2.453"
checkRedirect "2.454"            "dynamic-2.454"
checkRedirect "2.455"            "dynamic-2.454"
checkRedirect "2.456"            "dynamic-2.454"
checkRedirect "2.457"            "dynamic-2.454"

exit $result
