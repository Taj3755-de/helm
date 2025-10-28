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

        stage('Scan Docker Image with Trivy') {
            steps {
                sh '''
                ./trivy image --severity HIGH,CRITICAL --exit-code 1 --ignore-unfixed $REGISTRY/$IMAGE_NAME:latest || {
                    echo ">>> Security scan failed: CRITICAL/HIGH vulnerabilities found!"
                    exit 1
                }
                echo ">>> Trivy scan passed ✅"
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
            echo ">>> Copying Helm chart to Kubernetes master..."
            scp -o StrictHostKeyChecking=no -r ./helm rocky@172.31.86.230:/home/rocky/my-nginx-app/

            echo ">>> Deploying with Helm on Kubernetes..."
            ssh -o StrictHostKeyChecking=no $K8S_MASTER "
                helm upgrade --install nginx-release /home/rocky/my-nginx-app/nginx \
                    --set image.repository=$REGISTRY/$IMAGE_NAME \
                    --set image.tag=latest
            "
            '''
        }
    }
}
    }
}
