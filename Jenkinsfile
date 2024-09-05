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
                withAWS(credentials: '3ca4bfdf-cfdb-418e-94db-3f84398c4f37', region: 'ap-south-1') {
                    sh 'aws deploy create-deployment --application-name web-app --deployment-group-name web-deployment-group --github-location repository=Raghavarora09/task-pipeline,commitId=${GIT_COMMIT}'
                }
            }
        }
    }
}