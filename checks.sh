#!/bin/bash
set -eux -o pipefail

DefaultLocale="en_US.utf8"
DefaultMavenVersion="3.8.6"
DefaultJDKVersion="jdk-11"

uname -a
if test -e /etc/os-release; then
    cat /etc/os-release
fi

if test -e /proc/cpuinfo; then
    cat /proc/cpuinfo
fi

if test -e /proc/meminfo; then
    cat /proc/meminfo
fi

if [[ "$(locale -a)" =~ ${DefaultLocale} ]]; then
    echo "${DefaultLocale} locale is available"
else
    echo "ERROR ${DefaultLocale} locale is not available $(locale -a)"
    exit 1
fi

if getent passwd jenkins >/dev/null; then
    echo "jenkins user exists"
else
    echo "ERROR jenkins user does not exist"
    exit 1
fi

if [[ "$(whoami)" != "jenkins" ]]; then
    echo "ERROR Not running as jenkins user"
    echo "whoami: $(whoami)"
    exit 1
fi

if sudo -n whoami; then
    echo "ERROR running as root possible"
    exit 1
fi

set +u
if [[ -z "${JAVA_HOME}" ]]; then
    echo "ERROR: the 'JAVA_HOME' environment variable is undefined"
    exit 1
fi
set -u

if [ $# -ge 1 ] && [ -n "$1" ]; then
    echo "label of the node: $1"
    jdk="${DefaultJDKVersion}"
    if [ "$1" = "maven-8" ]; then
        jdk="jdk-8"
    elif [ "$1" = "maven-17" ]; then
        jdk="jdk-17"
    elif [ "$1" = "maven" ]; then
        jdk="jdk-8"
    elif [ "$1" = "jdk8" ]; then
        jdk="jdk-8"
    elif [ "$1" = "kubernetes" ]; then
        jdk="jdk-8"
    fi
    if [[ "$(mvn -v 2>&1)" != *"${jdk}"* ]]; then
        echo "ERROR JDK not matching what is expected: "
        echo "expecting ${jdk} for label $1"
        echo "$(mvn -v 2>&1)"
        exit 1
    else
        echo "JDK ok ${jdk} for $1"
    fi
fi

if [[ "$(mvn -v  2>&1)" != *"${DefaultMavenVersion}"* ]]; then
    echo "ERROR Maven version not matching what is expected : "
    echo "expecting ${DefaultMavenVersion} for label $1"
    echo "found $(mvn -v 2>&1)"
    exit 1
else
    echo "MAVEN ok: ${DefaultMavenVersion} for $1"
fi
