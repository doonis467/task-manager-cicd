pipeline {
    agent { label 'windows-java21-agent' }

    triggers {
        pollSCM('* * * * *')
    }

    options {
        timestamps()
        disableConcurrentBuilds()
        skipDefaultCheckout(true)
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    stages {
        stage('Checkout') {
            steps {
                deleteDir()
                checkout scm
            }
        }

        stage('Check Java Version') {
            steps {
                bat 'powershell -NoProfile -ExecutionPolicy Bypass -File scripts/Check-Toolchain.ps1 -RequiredJava 21 -JavaOnly'
            }
        }

        stage('Toolchain') {
            steps {
                bat 'java -version'
                bat 'mvn -version'
                bat 'git --version'
            }
        }

        stage('Build and Verify') {
            steps {
                bat 'mvn -B -ntp clean verify'
            }
        }

        stage('Generate Reports') {
            steps {
                bat 'mvn -B -ntp surefire-report:report-only'
                bat 'mvn -B -ntp jacoco:report'
            }
        }
    }

    post {
        always {
            junit allowEmptyResults: true,
                  testResults: 'target/surefire-reports/TEST-*.xml,target/failsafe-reports/TEST-*.xml'

            archiveArtifacts artifacts: 'target/surefire-reports/**,target/failsafe-reports/**,target/site/**',
                             allowEmptyArchive: true
        }

        success {
            archiveArtifacts artifacts: 'target/task-manager-cicd-1.0.0.jar',
                             fingerprint: true
        }

        failure {
            echo 'Pipeline failed. See Console Output.'
        }

        unstable {
            echo 'Pipeline unstable. Check test reports.'
        }
    }
}