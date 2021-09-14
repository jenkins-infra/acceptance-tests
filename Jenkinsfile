#!/usr/bin/env groovy

// Only one build running at a time, stop prior build if new build starts
def buildNumber = BUILD_NUMBER as int; if (buildNumber > 1) milestone(buildNumber - 1); milestone(buildNumber) // Thanks to jglick

/*
 * Making sure that we can follow the steps necessary to install the latest
 * release for Debian/Ubuntu machine.
 */

properties([
    buildDiscarder(logRotator(numToKeepStr: '5')),
    pipelineTriggers([cron('@hourly')]),
])

// Define processors
def Processors = [ "arm64docker", "docker", "ppc64ledocker", "s390xdocker" ]

// Generate a parallel step for each label in labels
def generateParallelSteps(labels) {
    def parallelNodes = [:]
    for (unboundLabel in labels) {
        def label = unboundLabel // Bind label before the closure
        parallelNodes[label] = {
            node('docker') {
                timestamps {
                    docker.image('debian').inside('-u 0:0') {
                        stage('Prepare Container') {
                            sh 'apt-get update -q -y && apt-get install -q -y --allow-change-held-packages wget apt-transport-https gnupg2'
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
        }
    }  
    return parallelNodes
}


timeout(unit: 'MINUTES', time:29) {
       stage("processor") {
               parallel generateParallelSteps(Processors)
        }
}
