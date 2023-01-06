#!/usr/bin/env groovy

properties([
    buildDiscarder(logRotator(numToKeepStr: '5')), // Keep up to 5 builds
    disableConcurrentBuilds(abortPrevious: true),  // Only run one build at a time
    pipelineTriggers([cron('@hourly')]),           // Run once an hour
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
