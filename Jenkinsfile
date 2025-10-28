pipeline {
  agent any

  parameters {
    choice(name: 'DEPLOY_ENV', choices: ['staging','production'], description: 'Select deployment environment')
  }

  environment {
    REGISTRY = "172.31.3.134:5000"
    IMAGE_NAME = "nginx-app"
    K8S_MASTER = "rocky@172.31.86.230"   // change as needed
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build') {
      steps {
        sh 'docker build -t ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER} .'
      }
    }

    stage('Trivy Scan') {
      steps {
        sh '''
          if ! command -v trivy >/dev/null 2>&1; then
            curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh
          fi
          trivy image --severity HIGH,CRITICAL --exit-code 1 --ignore-unfixed ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER} || { echo "CRITICAL/HIGH vuln found"; exit 1; }
        '''
      }
    }

    stage('Push') {
      steps {
        sh 'docker push ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}'
      }
    }

    stage('Lint Helm') {
      steps {
        sh 'helm lint helm/nginx || true'
      }
    }

    stage('Deploy') {
      steps {
        sshagent(['kube-master-ssh']) {
          sh """
            scp -o StrictHostKeyChecking=no -r helm ${K8S_MASTER}:/home/rocky/my-nginx-app/
            ssh -o StrictHostKeyChecking=no ${K8S_MASTER} 'mkdir -p /home/rocky/my-nginx-app/helm && helm upgrade --install nginx-release /home/rocky/my-nginx-app/helm/nginx -n ${params.DEPLOY_ENV} -f /home/rocky/my-nginx-app/helm/nginx/values-${params.DEPLOY_ENV}.yaml --set image.repository=${REGISTRY}/${IMAGE_NAME} --set image.tag=${BUILD_NUMBER}'
          """
        }
      }
    }

    stage('Post Deploy Check') {
      steps {
        sshagent(['kube-master-ssh']) {
          sh 'ssh -o StrictHostKeyChecking=no ${K8S_MASTER} "/bin/kubectl get pods -n ${params.DEPLOY_ENV} -o wide"'
        }
      }
    }
  }
}
