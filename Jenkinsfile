#!/usr/bin/env groovy

/*
 * Making sure that we can follow the steps necessary to install the latest
 * release RPM for redhat/almalinux/rocky machine.
 */

properties([
    buildDiscarder(logRotator(numToKeepStr: '15')),
    // Do not resume build after controller restart
    disableResume(),
    durabilityHint('PERFORMANCE_OPTIMIZED'),
    // Only one build running at a time, stop prior build if new build starts
    disableConcurrentBuilds(abortPrevious: true),
    pipelineTriggers([cron('H H/8 * * *')]), // Run once every 8 hours (three times a day)
])

node('docker') {
    timestamps {
        docker.image('almalinux').inside('-u 0:0') {
            stage('Prepare Container') {
                sh 'yum install -y wget epel-release'
            }

            stage('Add the rpm key') {
                sh 'wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo'
                sh 'rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key'
            }

            stage('Install Jenkins from rpm') {
                sh 'yum install -y jenkins'
            }
        }
    }
}
