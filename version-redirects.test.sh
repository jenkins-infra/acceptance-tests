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

checkRedirect "2.332.1.1"        "current"                # Unrecognized version takes current
checkRedirect "2.332.1"          "dynamic-stable-2.332.1"
checkRedirect "2.332.2"          "dynamic-stable-2.332.2"
checkRedirect "2.332.3"          "dynamic-stable-2.332.3"

checkRedirect "2.361.1"          "dynamic-stable-2.361.1"
checkRedirect "2.361.2"          "dynamic-stable-2.361.2"
checkRedirect "2.361.3"          "dynamic-stable-2.361.3"
checkRedirect "2.361.4"          "dynamic-stable-2.361.4"

checkRedirect "2.375.1"          "dynamic-stable-2.375.1"
checkRedirect "2.375.2"          "dynamic-stable-2.375.1"
checkRedirect "2.375.3"          "dynamic-stable-2.375.3"

checkRedirect "2.387.1"          "dynamic-stable-2.387.1"

checkRedirect "2.388"            "dynamic-2.388"
checkRedirect "2.399"            "dynamic-2.393"
checkRedirect "2.400"            "dynamic-2.393"
checkRedirect "2.401"            "dynamic-2.393"
checkRedirect "2.402"            "dynamic-2.393"

exit $result
