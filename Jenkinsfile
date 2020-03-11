#!/usr/bin/env groovy

properties([
    [$class: 'jenkins.model.BuildDiscarderProperty', strategy: [$class: 'LogRotator', numToKeepStr: '5']],
    pipelineTriggers([cron('@hourly')]),
])

// Only one build at a time, abort older builds if newer builds start
// See https://jenkins.io/blog/2016/10/16/stage-lock-milestone/#putting-it-all-together
lock(resource: 'infra/acceptance-tests/update-site', inversePrecedence: true) {
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
}
