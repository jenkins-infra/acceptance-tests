#!/usr/bin/env groovy

// Only one build running at a time, stop prior build if new build starts
def buildNumber = BUILD_NUMBER as int; if (buildNumber > 1) milestone(buildNumber - 1); milestone(buildNumber) // Thanks to jglick

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
        docker.image('centos').inside('-u 0:0') {
            stage('Prepare Container') {
                sh 'yum install -y wget'
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
