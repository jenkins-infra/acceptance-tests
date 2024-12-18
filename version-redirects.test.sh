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
    if [ -n "$header" ]; then
      echo >&2 "    Actual header: $header"
    else
      echo >&2 "    Actual header: is unexpectedly empty"
    fi
    if [ -n "$stderr" ]; then
      echo >&2 "    Actual stderr: $stderr"
    fi
    result=1
  fi
}

checkRedirect "2.440.1.1"        "update-center/current" # Unrecognized version takes current

checkRedirect "2.440.1"          "dynamic-stable-2.440.1"
checkRedirect "2.440.3"          "dynamic-stable-2.440.3"

checkRedirect "2.452.1"          "dynamic-stable-2.452.1"
checkRedirect "2.452.3"          "dynamic-stable-2.452.3"

checkRedirect "2.462.1"          "dynamic-stable-2.462.1"
checkRedirect "2.462.3"          "dynamic-stable-2.462.3"

checkRedirect "2.479.1"          "dynamic-stable-2.479.1"

checkRedirect "2.486"            "dynamic-2.482"
checkRedirect "2.487"            "dynamic-2.482"
checkRedirect "2.488"            "dynamic-2.482"
checkRedirect "2.489"            "dynamic-2.489"
checkRedirect "2.490"            "dynamic-2.489"

exit $result
