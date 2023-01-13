#!/usr/bin/env groovy

/*
 * Making sure that we can follow the steps necessary to install the latest
 * release RPM for redhat/almalinux/rocky machine.
 */

properties([
    buildDiscarder(logRotator(numToKeepStr: '5')),
    pipelineTriggers([cron('@hourly')]),
    // Only one build running at a time, stop prior build if new build starts
    disableConcurrentBuilds(abortPrevious: true),
    // Do not resume build after controller restart
    disableResume(),
])

node('docker') {
    timestamps {
        docker.image('almalinux').inside('-u 0:0') {
            stage('Prepare Container') {
                sh 'yum install -y wget epel-release'
            }

            stage('Add the rpm key') {
                sh 'wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat/jenkins.repo'
                sh 'rpm --import https://pkg.jenkins.io/redhat/jenkins.io.key'
            }

            stage('Install Jenkins from rpm') {
                sh 'yum install -y jenkins'
            }
        }
    }
}
