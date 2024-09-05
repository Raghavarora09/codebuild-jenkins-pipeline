pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Deploy to AWS') {
            steps {
                withAWS(credentials: '662ee533-0a39-4315-b128-8bc8c95ce983', region: 'ap-south-1') {
                    sh 'aws deploy create-deployment --application-name web-app --deployment-group-name web-deployment-group --github-location repository=Raghavarora09/task-pipeline,commitId=${GIT_COMMIT}'
                }
            }
        }
    }
}