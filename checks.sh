#!/bin/bash
set -eux -o pipefail

echo "version 20220922_094500"

MavenVersion="3.8.6"
JDKdefault="jdk-11"

# uname -a
# if test -e /etc/os-release; then
#     cat /etc/os-release
# fi

# if test -e /proc/cpuinfo; then
#     cat /proc/cpuinfo
# fi

# if test -e /proc/meminfo; then
#     cat /proc/meminfo
# fi

# if [[ $(locale -a) =~ en_US.utf8 ]]; then
#     echo "en_US.utf8 locale is available"
# else
#     echo "ERROR en_US.utf8 locale is not available $(locale -a)"
#     exit 1
# fi

# if getent passwd jenkins >/dev/null; then
#     echo "jenkins user exists"
# else
#     echo "ERROR jenkins user does not exist"
#     exit 1
# fi

# if [ "$(whoami)" != "jenkins" ]; then
#     echo "ERROR Not running as jenkins user"
#     echo "whoami: $(whoami)"
#     exit 1
# fi

# if sudo -n whoami; then
#     echo "ERROR running as root possible"
#     exit 1
# fi

# set +u
# if [[ -z "${JAVA_HOME}" ]]; then
#     echo "ERROR JDK environement variable not defined"
#     exit 1
# fi
# set -u

# if [ $# -ge 1 ] && [ -n "$1" ]; then
#     echo "label of the node: $1"
#     jdk=$JDKdefault
#     if [ "$1" = "maven-8" ]; then
#         jdk="jdk-8"
#     elif [ "$1" = "maven-17" ]; then
#         jdk="jdk-17"
#     elif [ "$1" = "maven" ]; then
#         jdk="jdk-8"
#     elif [ "$1" = "jdk-8" ]; then
#         jdk="jdk-8"
#     elif [ "$1" = "kubernetes" ]; then
#         jdk="jdk-8"
#     fi
#     if [[ ${JAVA_HOME} != *"$jdk"* ]]; then
#         echo "ERROR JDK not matching what is expected : "
#         echo "expecting $jdk for label $1"
#         echo "found ${JAVA_HOME}"
#         exit 1
#     else
#         echo "JDK ok : ${JAVA_HOME} for $1"
#     fi
# fi
#
# if [[ $(mvn -v) != *"$MavenVersion"* ]]; then
#     echo "ERROR Maven version not matching what is expected : "
#     echo "expecting $MavenVersion for label $1"
#     echo "found $(mvn -v)"
#     exit 1
# else
#     echo "MAVEN ok : $MavenVersion for $1"
# fi
#
journalctl -u datadog-agent --no-pager --no-full --tail=100
