#!/usr/bin/env groovy

// Only one build running at a time, stop prior build if new build starts
def buildNumber = BUILD_NUMBER as int; if (buildNumber > 1) milestone(buildNumber - 1); milestone(buildNumber) // Thanks to jglick

properties([
    [$class: 'jenkins.model.BuildDiscarderProperty', strategy: [$class: 'LogRotator', numToKeepStr: '5']],
    pipelineTriggers([cron('@hourly')]),
])

node('docker') {
    docker.image('cloudbees/java-build-tools').inside() {
        stage('Run the tests') {
            checkout(
                [ $class: 'GitSCM',
                  branches: scm.branches, // Assumes the multibranch pipeline checkout branch definition is good enough
                  extensions: [
                        [ $class: 'CloneOption', honorRefspec: true, noTags: true ],
                        [ $class: 'LocalBranch', localBranch: env.BRANCH_NAME ],
                  ],
                  gitTool: scm.gitTool,
                  userRemoteConfigs: scm.userRemoteConfigs // Assumes the multibranch pipeline checkout remoteconfig is good enough
                ]
            )
            sh 'bash ./test.sh'
        }
    }
}
