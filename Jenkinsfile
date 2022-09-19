//!/usr/bin/env groovy

// Only one build running at a time, stop prior build if new build starts
def buildNumber = BUILD_NUMBER as int; if (buildNumber > 1) milestone(buildNumber - 1); milestone(buildNumber) // Thanks to jglick

properties([
    buildDiscarder(logRotator(numToKeepStr: '15')),
    disableResume(),
    durabilityHint('PERFORMANCE_OPTIMIZED'),
    pipelineTriggers([cron('H H/8 * * *')]), // Run once every 8 hours (three times a day)
])

// Define the sequential stages and the parallel steps inside each stage
def sequentialStages = [:]
// sequentialStages['Tool'] = [ 'java', 'maven', 'maven-windows', 'maven-11', 'maven-11-windows']
// sequentialStages['OS & Java'] = [ 'linux', 'windows', 'jdk8', 'jdk11']
// sequentialStages['Processor'] = [ 'arm64', 'amd64' ] // Remove ppc64le and s390x until virtual machine available 'ppc64le', 's390x'
// sequentialStages['Docker'] = [ 'arm64docker', 'docker', 'docker-windows' ] // Remove ppc64le and s390x until available again 'ppc64ledocker', 's390xdocker'
// sequentialStages['Memory'] = [ 'highmem', 'highram']
// sequentialStages['Cloud & Orchestrator'] = [ 'aci', 'aws', 'azure', 'kubernetes']
sequentialStages['Testing'] = [ 'maven-11' ]

// Generate a parallel step for each label in labels
def generateParallelSteps(labels) {
    def parallelNodes = [:]
    for (unboundLabel in labels) {
        def label = unboundLabel // Bind label before the closure
        parallelNodes[label] = {
            node(label) {
                if (isUnix()) {
                    // sh '''
                    //     uname -a
                    //     if test -e /etc/os-release; then
                    //         cat /etc/os-release
                    //     fi
                    //     if test -e /proc/cpuinfo; then
                    //         cat /proc/cpuinfo
                    //     fi
                    //     if test -e /proc/meminfo; then
                    //         cat /proc/meminfo
                    //     fi
                    // '''
                    def localeOutput = sh "locale -a"
                    // if (!localeOutput.contains("en_US.UTF-8")) {
                    //     error("Missing en_US.UTF-8 locale")
                    // }
                } else {
                    //bat 'set | findstr PROCESSOR'
                    echo "windows"
                }
            }
        }
    }
    return parallelNodes
}

timeout(unit: 'MINUTES', time:29) {
    for (unboundStage in sequentialStages) {
        def boundStage = unboundStage
        stage(boundStage.key) {
            parallel generateParallelSteps(sequentialStages[boundStage.key])
        }
    }
}
