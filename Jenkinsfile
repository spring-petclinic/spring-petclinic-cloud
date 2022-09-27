node {
    stage('test') {
        sh 'echo hello'
    }
    stage('learning') {
        git url: 'https://github.com/GitPracticeRepo/game-of-life.git',
            branch: 'master'
    }
    stage('build') {
        sh 'mvn package'
    }
}