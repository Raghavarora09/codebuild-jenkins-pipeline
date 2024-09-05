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
                withAWS(credentials: 'your-aws-credentials-id', region: 'us-west-2') {
                    sh 'aws deploy create-deployment --application-name web-app --deployment-group-name web-deployment-group --github-location repository=scifigurmeet/justapipeline,commitId=${GIT_COMMIT}'
                }
            }
        }
    }
}