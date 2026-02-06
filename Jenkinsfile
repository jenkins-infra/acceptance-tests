properties([
    buildDiscarder(logRotator(numToKeepStr: '15')),
    disableResume(),
    durabilityHint('PERFORMANCE_OPTIMIZED'),
    pipelineTriggers([cron('@daily')]),
])

timeout(unit: 'MINUTES', time:5) {
  node('maven-21') {
    withEnv([
      'ARCHIVE_PATH=/cache/maven-bom-local-repo.tar.gz',
      'ARCHIVE_AGE_IN_DAYS=7',
      'ARCHIVE_MIN_SIZE_IN_KB=998000'
    ]) {
      stage('Check presence of the cache archive') {
        sh '''
          if [[ ! -f "${ARCHIVE_PATH}" ]]
          then
              echo "ERROR: file ${ARCHIVE_PATH} does not exist."
              exit 1
          fi
          echo "File ${ARCHIVE_PATH} exists."
        '''
      }
      stage('Check age of the cache archive') {
        sh '''
          if [[ "$(find "${ARCHIVE_PATH}" -mtime +"${ARCHIVE_AGE_IN_DAYS}" -print)" ]]
          then
              echo "ERROR: file ${ARCHIVE_PATH} is older than ${ARCHIVE_AGE_IN_DAYS} days. It is suspicious: something went wrong."
              exit 1
          fi
          echo "File ${ARCHIVE_PATH} has been modified less than ${ARCHIVE_AGE_IN_DAYS} days ago."
        '''
      }
      stage('Check size of the cache archive') {
        sh '''
        archive_size_kb="$(du -s "${ARCHIVE_PATH}" | awk '{print $1}')"
        if [[ "${archive_size_kb}" -le "${ARCHIVE_MIN_SIZE_IN_KB}" ]]
        then
            echo "ERROR: file ${ARCHIVE_PATH} weight less than ${ARCHIVE_MIN_SIZE_IN_KB} Kb. It is suspicious: something went wrong."
            exit 1
        fi
        echo "File ${ARCHIVE_PATH} weight ${archive_size_kb} Kb, which greater than the minimum threshold of ${ARCHIVE_MIN_SIZE_IN_KB} Kb."
        '''
      }
    }
  }
}
