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
                withAWS(credentials: 'AKIAZI2LB5EKVXCYIBHH', region: 'ap-south-1') {
                    sh 'aws deploy create-deployment --application-name web-app --deployment-group-name web-deployment-group --github-location repository=Raghavarora09/task-pipeline,commitId=${GIT_COMMIT}'
                }
            }
        }
    }
}