#!/usr/bin/env groovy

/*
 * Making sure that we can follow the steps necessary to install the latest
 * release RPM for redhat/centos machine:
 */

properties([
    [$class: 'jenkins.model.BuildDiscarderProperty',
        strategy: [$class: 'LogRotator', numToKeepStr: '5']],
    pipelineTriggers([cron('@hourly')]),
])

node('docker') {
    timestamps {
        docker.image('debian').inside('-u 0:0') {
            stage('Prepare Container') {
                sh 'apt-get update -qy && apt-get install -qy --force-yes wget apt-transport-https'
            }

            stage('Add the rpm key') {
                sh 'wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | apt-key add -'
            }

            stage('Install Jenkins from rpm') {
                sh 'echo "deb https://pkg.jenkins.io/debian binary/" >> /etc/apt/sources.list'
                sh 'apt-get update && apt-get install -qy jenkins'
            }
        }
    }
}
