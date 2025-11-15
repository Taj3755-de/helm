pipeline {
    agent any

    environment {
        AWS_REGION      = "us-east-1"
        ACCOUNT_ID      = "157314643992"
        REPO            = "finacplus/app-01v"
        IMAGE_URI       = "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO}"
        K8S_NAMESPACE   = "default"
        K8S_MASTER      = "rocky@172.31.86.230"     // CHANGE THIS
        SSH_CRED        = "kube-master-ssh"       // Jenkins SSH key ID
    }

    stages {

        /* ------------------------------------------------------------
                      BUILD & PUSH IMAGE TO ECR
        ------------------------------------------------------------ */

        stage('Checkout Code') {
            steps { checkout scm }
        }

        stage('Login to AWS ECR') {
            steps {
                sh """
                aws ecr get-login-password --region ${AWS_REGION} \
                | docker login --username AWS --password-stdin ${IMAGE_URI}
                """
            }
        }

        stage('Build Docker Image') {
            steps { sh "docker build -t app-01v ." }
        }

        stage('Tag Docker Image') {
            steps { sh "docker tag app-01v:latest ${IMAGE_URI}:${BUILD_NUMBER}" }
        }

        stage('Push Image to ECR') {
            steps { sh "docker push ${IMAGE_URI}:${BUILD_NUMBER}" }
        }

        /* ------------------------------------------------------------
                    DETERMINE BLUE vs GREEN TARGET
        ------------------------------------------------------------ */

        stage('Determine Active Color') {
            steps {
                sshagent([SSH_CRED]) {
                    script {
                        ACTIVE = sh(
                            script: """
                                ssh -o StrictHostKeyChecking=no ${K8S_MASTER} \
                                "kubectl get svc finacplus-service -n ${K8S_NAMESPACE} -o jsonpath='{.spec.selector.color}'"
                            """,
                            returnStdout: true
                        ).trim()

                        env.ACTIVE_COLOR = ACTIVE
                        env.NEW_COLOR = (ACTIVE == "blue") ? "green" : "blue"

                        echo "Active Color = ${env.ACTIVE_COLOR}"
                        echo "New Color to Deploy = ${env.NEW_COLOR}"
                    }
                }
            }
        }

        /* ------------------------------------------------------------
                    PREPARE YAML & COPY TO K8s MASTER
        ------------------------------------------------------------ */

        stage('Update Deployment YAML') {
            steps {
                script {
                    sh """
                    sed -i 's|IMAGE_PLACEHOLDER|${IMAGE_URI}:${BUILD_NUMBER}|g' k8s/deployment-${NEW_COLOR}.yaml
                    """
                }
            }
        }

        stage('Copy YAML to K8s Master') {
            steps {
                sshagent([SSH_CRED]) {
                    sh """
                    scp -o StrictHostKeyChecking=no k8s/deployment-${NEW_COLOR}.yaml \
                        ${K8S_MASTER}:/home/rocky/
                    """
                }
            }
        }

        /* ------------------------------------------------------------
                        APPLY NEW COLOR DEPLOYMENT
        ------------------------------------------------------------ */

        stage('Deploy Inactive Color') {
            steps {
                sshagent([SSH_CRED]) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ${K8S_MASTER} "
                        kubectl apply -f /home/rocky/deployment-${NEW_COLOR}.yaml -n ${K8S_NAMESPACE}
                    "
                    """
                }
            }
        }

        stage('Health Check New Deployment') {
            steps {
                sshagent([SSH_CRED]) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ${K8S_MASTER} "
                        kubectl rollout status deployment/app-${NEW_COLOR} \
                        -n ${K8S_NAMESPACE} --timeout=60s
                    "
                    """
                }
            }
        }

        /* ------------------------------------------------------------
                    SWITCH LIVE TRAFFIC TO NEW COLOR
        ------------------------------------------------------------ */

        stage('Switch Service to New Color') {
            steps {
                sshagent([SSH_CRED]) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ${K8S_MASTER} "
                        kubectl patch svc finacplus-service -n ${K8S_NAMESPACE} \
                        -p '{\"spec\":{\"selector\":{\"color\":\"${NEW_COLOR}\"}}}'
                    "
                    """
                }
            }
        }
    }

    /* ------------------------------------------------------------
                        ROLLBACK LOGIC
    ------------------------------------------------------------ */

    post {
        failure {
            echo "❌ Deployment failed, rolling back to ${env.ACTIVE_COLOR}"

            sshagent([SSH_CRED]) {
                sh """
                ssh -o StrictHostKeyChecking=no ${K8S_MASTER} "
                    kubectl patch svc finacplus-service -n ${K8S_NAMESPACE} \
                    -p '{\"spec\":{\"selector\":{\"color\":\"${ACTIVE_COLOR}\"}}}'
                "
                """
            }
        }

        success {
            echo "✅ Deployment success! Live color is now ${env.NEW_COLOR}"
        }
    }
}
