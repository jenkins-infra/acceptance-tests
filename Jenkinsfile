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
sequentialStages['Tool'] = [ 'maven', 'maven-11', 'maven-17', 'maven-21', 'maven-windows', 'maven-11-windows', 'maven-17-windows', 'maven-21-windows']
sequentialStages['Processor'] = [ 'amd64' ] // 'arm64', not tested, unavailable
sequentialStages['Docker'] = [ 's390xdocker', 'docker', 'docker-windows'] //'arm64docker', not tested, unavailable

// Generate a parallel step for each label in labels
def generateParallelSteps(labels) {
    def parallelNodes = [:]
    for (unboundLabel in labels) {
        def label = unboundLabel // Bind label before the closure
        parallelNodes[label] = {
            node(label) {
                if (isUnix()) {
                    checkout scm
                    sh 'bash ./checks.sh '+label
                } else {
                    bat 'set | findstr PROCESSOR'
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
