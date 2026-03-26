#!/bin/bash
#shellcheck disable=SC2310

set -eux -o pipefail

# A pull request can be used as validation for ci.jenkins.io when changing an agent template characteristics
# See process following TDD principle mentioned at https://github.com/jenkins-infra/helpdesk/issues/4949#issuecomment-3755425511
default_version_maven="3.9.13"
default_version_jdk="jdk-21"
default_locale="en_US.utf8"
default_user="jenkins"

label=''
if [[ $# -ge 1 && -n "$1" ]]; then
	label="$1"
	echo "INFO: label of the node: '${label}'"
fi

# Optional check bitmask flags
CHECK_NONE=0
CHECK_JAVAHOME=1
CHECK_MAVEN=2
CHECK_JDK=4
CHECK_DOCKER=8

# Default optional checks
optional_checks=$((CHECK_JAVAHOME | CHECK_MAVEN | CHECK_JDK))
case "${label}" in
	*docker*)
		optional_checks=$((optional_checks | CHECK_DOCKER));;
	linux)
		optional_checks=$((optional_checks | CHECK_DOCKER));; # docker controller and agents
	*)
esac
# Exceptions for trusted.ci.jenkins.io agents
if [[ "${JENKINS_URL:-}" == 'https://trusted.ci.jenkins.io/' ]]; then
	case "${label}" in
		docker|linux)
			# Default JDK not as expected
            optional_checks=$((optional_checks & ~CHECK_JDK));;
		updatecenter|agent-1)
			# No optional check
            optional_checks=$((CHECK_NONE));;
		*)
	esac
fi

# Exceptions for cert.ci.jenkins.io agents
if [[ "${JENKINS_URL:-}" == 'https://cert.ci.jenkins.io/' ]]; then
	case "${label}" in
		linux)
			# Default JDK not as expected
            optional_checks=$((optional_checks & ~CHECK_JDK));;
		*)
	esac
fi

# Exceptions for infra.ci.jenkins.io agents
if [[ "${JENKINS_URL:-}" == 'https://infra.ci.jenkins.io/' ]]; then
	case "${label}" in
		linux|jnlp*)
			# Kubernetes agents don't have docker and are set to JDK25 by default
            optional_checks=$((optional_checks & ~CHECK_DOCKER))
            optional_checks=$((optional_checks & ~CHECK_JDK));;
		*)
	esac
fi

has_check() {
    (( optional_checks & $1 ))
}

echo "INFO: Optional checks bitmask: ${optional_checks}"

# Allow Mark Waite to run the same script on his home network
if [[ -v JENKINS_ADVERTISED_HOSTNAME ]]; then
	default_user="jagent"
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

if [[ "$(locale -a || true)" =~ ${default_locale} ]]; then
	echo "INFO: ${default_locale} locale is available"
else
	echo "ERROR: ${default_locale} locale is not available $(locale -a)"
	failed=$((failed + 1))
fi

if getent passwd "${default_user}" >/dev/null; then
	echo "INFO: '${default_user}' user exists"
else
	echo "ERROR: '${default_user}' user does not exist"
	failed=$((failed + 2))
fi

if [[ "$(whoami || true)" != "${default_user}" ]]; then
	echo "ERROR: Not running as '${default_user}' user"
	echo "whoami: $(whoami)"
	failed=$((failed + 4))
fi

if sudo -n whoami; then
	echo "ERROR: running as root should not be possible"
	failed=$((failed + 8))
fi

if has_check CHECK_JAVAHOME; then
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
if has_check CHECK_MAVEN; then
	maven_version="$(mvn -v || true)"
	if [[ -n "${maven_version}" ]]; then
		echo "INFO: command 'mvn -v' executed with success"
	else
		set +e
		echo "ERROR: command 'mvn -v' failed to execute. Debugging informations below:"
		echo "${PATH}"
		which mvn
		mvn -v
		set -e
		failed=$((failed + 32))
	fi
else
	echo 'WARNING: "mvn -v" check skipped'
fi

# This check relies on the java version output of the 'mvn -v' command
# Java 8 needs to include '1.8' in the output
# Java 11 needs to include '11.' in the output
# Java 17 needs to include '17.' in the output
if has_check CHECK_JDK; then
	if [[ -n "${label}" ]]; then
		jdk="${default_version_jdk}"
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

		case "${jdk}" in
			jdk-8)
				expected_jdk="1.8";;
			jdk-11)
				expected_jdk="11.";;
			jdk-17)
				expected_jdk="17.";;
			jdk-21)
				expected_jdk="21";;
			jdk-25)
				expected_jdk="25";;
			*)
				echo "ERROR: JDK not matching the expected ${jdk} for label '${label}'"
				mvn -v 2>&1
				failed=$((failed + 64))
		esac

		jdk_from_maven=$(mvn -v | grep "Java version" | cut -d " " -f 3 || true)
		if [[ "${jdk_from_maven}" != *"${expected_jdk}"* ]]; then
			echo "ERROR: JDK from maven ${jdk_from_maven} not matching the expected ${expected_jdk} for label '${label}'"
			failed=$((failed + 64))
		else
			echo "INFO: JDK Version ok ${jdk_from_maven} for ${label}"
		fi
	fi
else
	echo 'WARNING: Expected JDK check skipped'
fi

if has_check CHECK_MAVEN; then
	maven_version="$(mvn -v || true)"
	if [[ "${maven_version}" != *"${default_version_maven}"* ]]; then
		echo "ERROR Maven version ${maven_version} does not match expected ${default_version_maven} default version for label '${label}'"
		failed=$((failed + 128))
	else
		echo "INFO: Maven version is matching the expected ${default_version_maven} version for label '${label}'"
	fi
else
	echo 'WARNING: Expected Maven version check skipped'
fi

# Docker check
if has_check CHECK_DOCKER; then
	docker_info="$(docker info || true)"
	if [[ -n "${docker_info}" ]]; then
		echo "INFO: docker is present as expected from '${label}' label, see info below:"
		echo "${docker_info}"
	else
		echo "ERROR: docker is not present as expected from '${label}' label, debugging informations below"
		set +e
		echo "${PATH}"
		which docker
		docker info
		set -e
		failed=$((failed + 256))
	fi
else
	echo 'WARNING: Docker check skipped'
fi

exit "${failed}"
