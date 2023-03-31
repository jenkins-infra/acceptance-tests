#!/usr/bin/env groovy

/*
 * Making sure that we can follow the steps necessary to install the latest
 * release for Debian/Ubuntu machine.
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

// Define processors
def Processors = [ "arm64docker", "s390xdocker", "docker" ] // "ppc64ledocker", excluded because test machine cannot download the jenkins package

// Generate a parallel step for each label in labels
def generateParallelSteps(labels) {
    def parallelNodes = [:]
    for (unboundLabel in labels) {
        def label = unboundLabel // Bind label before the closure
        parallelNodes[label] = {
            node(label) {
                timestamps {
                    docker.image('debian').inside('-u 0:0') {
                        stage('Prepare Container') {
                            sh 'apt-get update -q -y && apt-get install -q -y --allow-change-held-packages curl apt-transport-https'
                        }

                        stage('Add the apt key') {
                            sh 'curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null'
                        }

                        stage('Install Jenkins from apt') {
                            sh 'echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/ | tee /etc/apt/sources.list.d/jenkins.list > /dev/null'
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
       stage("Processor") {
               parallel generateParallelSteps(Processors)
        }
}
