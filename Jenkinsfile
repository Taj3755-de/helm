pipeline {
    agent any

    environment {
        REGISTRY = "172.31.3.134:5000"
        IMAGE_NAME = "nginx-app"
        K8S_MASTER = "rocky@172.31.86.230"
    }

    stages {
        stage('Build Docker Image') {
            steps {
                sh '''
                echo ">>> Building Docker image..."
                docker build -t $REGISTRY/$IMAGE_NAME:latest .
                '''
            }
        }

        stage('Push to Registry') {
            steps {
                sh '''
                echo ">>> Pushing image to registry..."
                docker push $REGISTRY/$IMAGE_NAME:latest
                '''
            }
        }

stage('Deploy via Helm on K8s Master') {
    steps {
        sshagent(['kube-master-ssh']) {
            sh '''
            echo ">>> Deploying with Helm on Kubernetes..."

            ssh -o StrictHostKeyChecking=no rocky@172.31.3.134 "
                helm upgrade --install nginx-release /home/rocky/my-nginx-app/helm/nginx \
                    --set image.repository=172.31.3.134:5000/nginx-app \
                    --set image.tag=latest
            "
            '''
        }
    }
}
}
