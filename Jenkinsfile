//!/usr/bin/env groovy

// Only one build running at a time, stop prior build if new build starts
def buildNumber = BUILD_NUMBER as int; if (buildNumber > 1) milestone(buildNumber - 1); milestone(buildNumber) // Thanks to jglick

properties([
    buildDiscarder(logRotator(numToKeepStr: '15')),
    disableResume(),
    durabilityHint('PERFORMANCE_OPTIMIZED'),
    pipelineTriggers([cron('H H/8 * * *')]), // Run once every 8 hours (three times a day)
])

def categorizedLabels = [:]
// Labels requested in https://github.com/jenkins-infra/pipeline-library/blob/master/vars/buildPlugin.groovy and https://github.com/jenkins-infra/pipeline-library/blob/master/vars/buildPluginWithGradle.groovy
categorizedLabels['Maven and JDK'] = [ 'maven-8', 'maven-11', 'maven-17', 'maven-21', 'maven-25', 'maven-8-windows', 'maven-11-windows', 'maven-17-windows', 'maven-21-windows', 'maven-25-windows']
categorizedLabels['VM Types'] = [ 'ubuntu-22-amd64-maven8', 'ubuntu-22-amd64-maven11', 'ubuntu-22-amd64-maven17', 'ubuntu-22-amd64-maven21', 'ubuntu-22-arm64-maven17', 'ubuntu-22-arm64-maven21', 'ubuntu-22-amd64-highmem-maven17']
categorizedLabels['Linux Processors'] = [ 's390x', 'linux-amd64', 'linux-arm64']
categorizedLabels['Docker Platforms'] = [ 's390xdocker', 'docker', 'docker-windows', 'arm64docker', 'windows-2019', 'windows-2022', 'windows-2025']
categorizedLabels['Spot and OnDemand'] = [ 'docker-windows && spot', 'docker-windows && nonspot', 'docker && spot', 'docker && nonspot', 'docker-highmem-nonspot', 'docker-highmem && spot', 'docker-highmem && nonspot'] // Pipeline Library (mostly), but also Docker-*agent and Jenkins ATH

// Generate a parallel step for each label
def generateParallelSteps(categorizedLabels) {
    def parallelNodes = [:]
    categorizedLabels.each { categoryName, labels ->
        labels.each { unboundLabel ->
            def label = unboundLabel
            def stageName = "${label} / ${categoryName}"
            parallelNodes[stageName] = {
                stage(stageName) {
                    node(label) {
                        withEnv(["NODE_LABEL=${label}"]) {
                            checkout scm
                            if (isUnix()) {
                                sh 'bash ./checks.sh "${NODE_LABEL}"'
                            } else {
                                pwsh 'pwsh ./checks.ps1 -Label "${env:NODE_LABEL}"'
                            }
                        }
                    }
                }
            }
        }
    }
    return parallelNodes
}

timeout(unit: 'MINUTES', time: 29) {
    parallel generateParallelSteps(categorizedLabels)
}

publishBuildStatusReport()
