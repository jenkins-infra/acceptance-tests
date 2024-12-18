#!/bin/bash

# Test Jenkins requests for metadata gets redirected to correct version of update center.

UPDATE_CENTER='https://updates.jenkins.io/'

result=0

function checkRedirect() {
  version="$1"
  target="$2"
  echo ====== $version $target ======
  stderr="$(curl -sSIL "${UPDATE_CENTER}/update-center.json?id=default&version=${version}" 2>&1 > /dev/null)"
  header="$(grep -i 'location:' <<< "$stderr" | sed 's,^.*[.]jenkins[.]io/,jenkins.io/,g' | tr -d '\r')"
  #target="$( sed 's~.*/\([^/]*\)/update-center.json~\1~' <<< "$header")"

  expected="jenkins.io/${target}/update-center.json"
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

checkRedirect "2.426.1.1"        "current"                # Unrecognized version takes current

checkRedirect "2.426.3"          "dynamic-stable-2.426.3"

checkRedirect "2.440.1"          "dynamic-stable-2.440.1"
checkRedirect "2.440.2"          "dynamic-stable-2.440.2"
checkRedirect "2.440.3"          "dynamic-stable-2.440.3"

checkRedirect "2.452.1"          "dynamic-stable-2.452.1"
checkRedirect "2.452.2"          "dynamic-stable-2.452.2"
checkRedirect "2.452.3"          "dynamic-stable-2.452.3"

checkRedirect "2.462.1"          "dynamic-stable-2.462.1"
checkRedirect "2.462.2"          "dynamic-stable-2.462.2"
checkRedirect "2.462.3"          "dynamic-stable-2.462.3"

checkRedirect "2.453"            "dynamic-2.453"
checkRedirect "2.454"            "dynamic-2.454"
checkRedirect "2.455"            "dynamic-2.454"
checkRedirect "2.456"            "dynamic-2.454"
checkRedirect "2.457"            "dynamic-2.454"
checkRedirect "2.458"            "dynamic-2.454"
checkRedirect "2.459"            "dynamic-2.459"
checkRedirect "2.460"            "dynamic-2.460"
checkRedirect "2.461"            "dynamic-2.460"
checkRedirect "2.462"            "dynamic-2.462"
checkRedirect "2.463"            "dynamic-2.463"
checkRedirect "2.464"            "dynamic-2.464"
checkRedirect "2.465"            "dynamic-2.464"
checkRedirect "2.466"            "dynamic-2.464"
checkRedirect "2.467"            "dynamic-2.464"
checkRedirect "2.468"            "dynamic-2.464"
checkRedirect "2.469"            "dynamic-2.464"
checkRedirect "2.470"            "dynamic-2.464"

checkRedirect "2.479"            "dynamic-2.479"

exit $result
