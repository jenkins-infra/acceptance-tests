#!/usr/bin/env groovy

properties([
    [$class: 'jenkins.model.BuildDiscarderProperty', strategy: [$class: 'LogRotator', numToKeepStr: '5']],
    pipelineTriggers([cron('@hourly')]),
])

node('docker') {
    docker.image('cloudbees/java-build-tools').inside() {
        stage('Run the tests') {
            git url: 'https://github.com/jenkins-infra/acceptance-tests.git', branch: "update-site"
            sh 'bash ./test.sh'
        }
    }
}
