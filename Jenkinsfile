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
// Labels requested in https://github.com/jenkins-infra/pipeline-library/blob/master/vars/buildPlugin.groovy and https://github.com/jenkins-infra/pipeline-library/blob/master/vars/buildPluginWithGradle.groovy
sequentialStages['Maven and JDK'] = [ 'maven-8', 'maven-11', 'maven-17', 'maven-21', 'maven-25', 'maven-8-windows', 'maven-11-windows', 'maven-17-windows', 'maven-21-windows', 'maven-25-windows']
sequentialStages['VM Types'] = [ 'ubuntu-22-amd64-maven8', 'ubuntu-22-amd64-maven11', 'ubuntu-22-amd64-maven17', 'ubuntu-22-amd64-maven21', 'ubuntu-22-arm64-maven17', 'ubuntu-22-arm64-maven21', 'ubuntu-22-amd64-highmem-maven17']
sequentialStages['Linux Processors'] = [ 's390x', 'linux-amd64', 'linux-arm64']
sequentialStages['Docker Platforms'] = [ 's390xdocker', 'docker', 'docker-windows', 'arm64docker']
sequentialStages['Spot and OnDemand'] = [ 'docker-windows && spot', 'docker-windows && nonspot', 'docker && spot', 'docker && nonspot', 'docker-highmem-nonspot'] // Pipeline Library (mostly), but also Docker-*agent and Jenkins ATH

// Generate a parallel step for each label in labels
def generateParallelSteps(labels) {
    def parallelNodes = [:]
    for (unboundLabel in labels) {
        def label = unboundLabel // Bind label before the closure
        parallelNodes[label] = {
            node(label) {
                withEnv(["NODE_LABEL=${label}"]) {
                    checkout scm
                    if (isUnix()) {
                        sh 'bash ./checks.sh "${NODE_LABEL}"'
                    } else {
                        pwsh 'pwsh ./checks.ps1 "${env:NODE_LABEL}"'
                    }
                }
            }
        }
    }
    return parallelNodes
}

timeout(unit: 'MINUTES', time:29) {
    for (unboundStage in sequentialStages) {
        def boundStage = unboundStage // Bind label before the closure
        stage(boundStage.key) {
            parallel generateParallelSteps(sequentialStages[boundStage.key])
        }
    }
}
