#!/usr/bin/env groovy

properties([
    buildDiscarder(logRotator(numToKeepStr: '15')),
    // Do not resume build after controller restart
    disableResume(),
    durabilityHint('PERFORMANCE_OPTIMIZED'),
    pipelineTriggers([cron('@daily')]),
])

// TODO: specify architecture and add corresponding processors if more than amd64 agents are used by docker image jobs on this controller
// Define processors
def ProcessorsLabelsAndDockerBakeTargets = [
    'ubuntu-amd64-maven-21': ['alpine_jdk21', 'debian_jdk25'],
    'ubuntu-arm64-maven-21': ['arm64'],
    'win-2022-amd64-maven-21': ['windowsservercore-ltsc2022']
]

// Generate a parallel step for each label in labels
def generateParallelSteps(processors) {
    def parallelNodes = [:]
    processors.each { unboundLabel, unboundTargetList ->
        // Bind before the closure
        def label = unboundLabel
        def targetList = unboundTargetList
        targetList.each { unboundTarget ->
            def target = unboundTarget
            def combination = "$target built on $label"
            parallelNodes[combination] = {
                node(label) {
                    timestamps {
                        withEnv([
                            "REVISION=2.546",
                            "DOCKER_BAKE_TARGET_TO_BUILD=$target"
                        ]) {
                            stage("Retrieve jenkinsci/docker at a specific revision") {
                                if (isUnix()) {
                                    sh 'git clone https://github.com/jenkinsci/docker && cd docker && git checkout "${REVISION}"'
                                } else {
                                    pwsh 'git clone https://github.com/jenkinsci/docker && cd docker && git checkout "${REVISION}"'
                                }
                            }
                            stage("Build docker bake target") {
                                dir('docker') {
                                    if (isUnix()) {
                                        sh '''
                                            docker info
                                            # Fallback to buildarch-% in case the target is an "architecture" one
                                            make "build-${DOCKER_BAKE_TARGET_TO_BUILD}" || make "buildarch-${DOCKER_BAKE_TARGET_TO_BUILD}"
                                        '''
                                    } else {
                                        // TODO: review when jenkinsci/docker/make.ps1 allows to specify the target to build
                                        pwsh '''
                                            docker info
                                            ./make.ps1 build
                                        '''
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }  
    return parallelNodes
}

timeout(unit: 'MINUTES', time: 60) {
    stage('Processor') {
        parallel generateParallelSteps(ProcessorsLabelsAndDockerBakeTargets)
    }
}
