#!/usr/bin/env groovy

properties([
    [$class: 'jenkins.model.BuildDiscarderProperty', strategy: [$class: 'LogRotator', numToKeepStr: '5']],
    pipelineTriggers([cron('@hourly')]),
])

node('docker') {
    timestamps {
        docker.image('debian').inside('-u 0:0') {
            stage('Prepare Container') {
                sh 'apt-get update -qy && apt-get install -qy --force-yes curl'
            }

            stage('Run the tests') {
                git url: '/home/ogondza/code/jenkins/infra-acceptance-tests', branch: "update-site"
                sh 'bash ./test.sh'
            }
        }
    }
}
