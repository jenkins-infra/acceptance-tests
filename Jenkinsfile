#!/usr/bin/env groovy

// Only one build running at a time, stop prior build if new build starts
def buildNumber = BUILD_NUMBER as int; if (buildNumber > 1) milestone(buildNumber - 1); milestone(buildNumber) // Thanks to jglick

/*
 * Making sure that we can follow the steps necessary to install the latest
 * release for Debian/Ubuntu machine.
 */

properties([
    buildDiscarder(logRotator(numToKeepStr: '5'))
    pipelineTriggers([cron('@hourly')]),
])

node('docker') {
    timestamps {
        docker.image('debian').inside('-u 0:0') {
            stage('Prepare Container') {
                sh 'apt-get update -qy && apt-get install -qy --force-yes wget apt-transport-https gnupg2'
            }

            stage('Add the apt key') {
                sh 'wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | apt-key add -'
            }

            stage('Install Jenkins from apt') {
                sh 'echo "deb https://pkg.jenkins.io/debian binary/" >> /etc/apt/sources.list'
                sh 'apt-get update && apt-get install -qy jenkins'
            }
        }
    }
}
