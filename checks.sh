#!/bin/bash
set -eux -o pipefail

DefaultLocale="en_US.utf8"
DefaultMavenVersion="3.9.0"
DefaultJDKVersion="jdk-11"

failed=0

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
	echo "ERROR: ${DefaultLocale} locale is not available $(locale -a)"
	failed=$((failed + 1))
fi

if getent passwd jenkins >/dev/null; then
	echo "'jenkins' user exists"
else
	echo "ERROR: 'jenkins' user does not exist"
	failed=$((failed + 2))
fi

if [[ "$(whoami)" != "jenkins" ]]; then
	echo "ERROR: Not running as 'jenkins' user"
	echo "whoami: $(whoami)"
	failed=$((failed + 4))
fi

if sudo -n whoami; then
	echo "ERROR: running as root should not be possible"
	failed=$((failed + 8))
fi

set +u
if [[ -z "${JAVA_HOME}" ]]; then
	echo "ERROR: the 'JAVA_HOME' environment variable is undefined"
	failed=$((failed + 16))
fi
set -u

# This check relies on the java version output of the 'mvn -v' command
# Java 8 needs to include '1.8' in the output
# Java 11 needs to include '11.' in the output
# Java 17 needs to include '17.' in the output
if [ $# -ge 1 ] && [ -n "$1" ]; then
	echo "label of the node: $1"

	jdk="${DefaultJDKVersion}"
	case "$1" in
  maven | maven-8 |jdk-8 | kubernetes)
    jdk="jdk-8";;
  maven-11 | jdk-11)
    jdk="jdk-11";;
  maven-17 | jdk-17)
    jdk="jdk-17";;
  maven-19 | jdk-19)
    jdk="jdk-19";;
  *)
    echo "Label '$1' specified. Using default jdk."
  esac

	case ${jdk} in
	jdk-8)
		jdknumber="1.8"
		;;
	jdk-11)
		jdknumber="11."
		;;
	jdk-17)
		jdknumber="17."
		;;
  jdk-19)
		jdknumber="19."
		;;
	*)
		echo "ERROR: JDK not matching the expected ${jdk} for label '$1'"
		mvn -v 2>&1
		failed=$((failed + 64))
		;;
	esac

    JDKfromMaven=$(mvn -v 2>&1 | grep "Java version" | cut -d " " -f 3)
	if [[ "${JDKfromMaven}" != *"${jdknumber}"* ]]; then
		echo "ERROR: JDK from maven ${JDKfromMaven} not matching the expected ${jdknumber} for label '$1'"
		failed=$((failed + 64))
	else
		echo "JDK Version ok ${JDKfromMaven} for $1"
	fi
fi

if [[ "$(mvn -v 2>&1)" != *"${DefaultMavenVersion}"* ]]; then
	echo "ERROR Maven version not matching what is expected : expecting ${DefaultMavenVersion} for label '$1' found $(mvn -v 2>&1)"
	failed=$((failed + 128))
else
	echo "Maven version ${DefaultMavenVersion} OK for label '$1'"
fi

exit ${failed}
