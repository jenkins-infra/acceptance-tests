#!/bin/bash
set -eux -o pipefail

DefaultLocale="en_US.utf8"
# A pull request can be used as validation for ci.jenkins.io when changing an agent template characteristics
# See process following TDD principle mentioned at https://github.com/jenkins-infra/helpdesk/issues/4949#issuecomment-3755425511
DefaultMavenVersion="3.9.12"
DefaultJDKVersion="jdk-21"
DefaultUser="jenkins"

label=''
if [ $# -ge 1 ] && [ -n "$1" ]; then
	label="$1"
	echo "INFO: label of the node: '${label}'"
fi

# Optional checks to perform, not run on every controller or label
optional_checks_to_perform='javahome mvn jdk'
# Exceptions for trusted.ci.jenkins.io agents
if [[ "${JENKINS_URL}" == 'https://trusted.ci.jenkins.io/' ]]; then
	case "${label}" in
		docker|linux)
			# Default JDK not as expected
            optional_checks_to_perform='javahome mvn';;
		updatecenter)
			# No JDK no mvn
            optional_checks_to_perform='';;
	esac
fi

# Allow Mark Waite to run the same script on his home network
if [ -v JENKINS_ADVERTISED_HOSTNAME ]; then
	DefaultUser="jagent"
fi

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
	echo "INFO: ${DefaultLocale} locale is available"
else
	echo "ERROR: ${DefaultLocale} locale is not available $(locale -a)"
	failed=$((failed + 1))
fi

if getent passwd ${DefaultUser} >/dev/null; then
	echo "INFO: '${DefaultUser}' user exists"
else
	echo "ERROR: '${DefaultUser}' user does not exist"
	failed=$((failed + 2))
fi

if [[ "$(whoami)" != "${DefaultUser}" ]]; then
	echo "ERROR: Not running as '${DefaultUser}' user"
	echo "whoami: $(whoami)"
	failed=$((failed + 4))
fi

if sudo -n whoami; then
	echo "ERROR: running as root should not be possible"
	failed=$((failed + 8))
fi

if [[ "${optional_checks_to_perform}" == *javahome* ]]; then
	set +u
	if [[ -z "${JAVA_HOME}" ]]; then
		echo "ERROR: the 'JAVA_HOME' environment variable is undefined"
		failed=$((failed + 16))
	fi
	set -u
else
	echo 'WARNING: JAVA_HOME check skipped'
fi

# Check for Maven CLI
if [[ "${optional_checks_to_perform}" == *mvn* ]]; then
	mvn -v 2>/dev/null >/dev/null || {
		set +e
		echo "ERROR: command 'mvn -v' failed to execute. Debugging informations below:";
		echo "${PATH}";
		which mvn;
		mvn -v;
		set -e
		exit 1;
	}
else
	echo 'WARNING: "mvn -v" check skipped'
fi

# This check relies on the java version output of the 'mvn -v' command
# Java 8 needs to include '1.8' in the output
# Java 11 needs to include '11.' in the output
# Java 17 needs to include '17.' in the output
if [[ "${optional_checks_to_perform}" == *jdk* ]]; then
	if [ -n "${label}" ]; then
		jdk="${DefaultJDKVersion}"
		case "${label}" in
			*maven-8 | *jdk-8 | *maven8)
				jdk="jdk-8";;
			*maven-11 | *jdk-11 | *maven11)
				jdk="jdk-11";;
			*maven-17 | *jdk-17 | *maven17)
				jdk="jdk-17";;
			*maven-21 | *jdk-21 | *maven21)
				jdk="jdk-21";;
			*maven-25 | *jdk-25 | *maven25)
				jdk="jdk-25";;
			*)
				echo "INFO: Label '${label}' specified. Using default jdk."
		esac

		case ${jdk} in
			jdk-8)
				jdknumber="1.8";;
			jdk-11)
				jdknumber="11.";;
			jdk-17)
				jdknumber="17.";;
			jdk-21)
				jdknumber="21";;
			jdk-25)
				jdknumber="25";;
			*)
				echo "ERROR: JDK not matching the expected ${jdk} for label '${label}'"
				mvn -v 2>&1
				failed=$((failed + 64))
		esac

		JDKfromMaven=$(mvn -v 2>&1 | grep "Java version" | cut -d " " -f 3)
		if [[ "${JDKfromMaven}" != *"${jdknumber}"* ]]; then
			if [[ "${label}" == 'docker' && "${JENKINS_URL}" == "trusted.ci.jenkins.io" ]]; then
				echo "WARNING: JDK from maven ${JDKfromMaven} not matching the expected ${jdknumber} for label '${label}' on trusted.ci.jenkins.io"
			else
				echo "ERROR: JDK from maven ${JDKfromMaven} not matching the expected ${jdknumber} for label '${label}'"
				failed=$((failed + 64))
			fi
		else
			echo "INFO: JDK Version ok ${JDKfromMaven} for ${label}"
		fi
	fi
else
	echo 'WARNING: Expected JDK check skipped'
fi

if [[ "${optional_checks_to_perform}" == *mvn* ]]; then
	if [[ "$(mvn -v 2>&1)" != *"${DefaultMavenVersion}"* ]]; then
		echo "ERROR Maven version not matching what is expected : expecting ${DefaultMavenVersion} for label '${label}' found $(mvn -v 2>&1)"
		failed=$((failed + 128))
	else
		echo "INFO: Maven version ${DefaultMavenVersion} OK for label '${label}'"
	fi
else
	echo 'WARNING: Expected Maven version check skipped'
fi

# Docker check
docker_expected=false
case "${label}" in
	*docker*)
		docker_expected=true;;
	linux)
		docker_expected=true;; # docker controller and agents
	*)
		echo "INFO: docker is not expected from '${label}' label"
esac
if [[ "${docker_expected}" == "true" ]]; then
	docker info 2>/dev/null >/dev/null && echo "INFO: docker is present as expected from \"${label}\" label" || {
		echo "ERROR: docker is not present as expected from \"${label}\" label, debugging informations below"
		set +e
		echo "${PATH}";
		which docker;
		docker info;
		set -e
		failed=$((failed + 256))
	}
fi

exit ${failed}
