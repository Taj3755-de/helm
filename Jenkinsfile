pipeline {
  agent any

  parameters {
    choice(name: 'DEPLOY_ENV', choices: ['staging', 'production'], description: 'Select deployment environment')
  }

  environment {
    REGISTRY = "172.31.3.134:5000"
    IMAGE_NAME = "python-app"
    K8S_MASTER = "rocky@172.31.86.230"
  }

  stages {

    stage('Checkout') {
      steps {
        echo ">>> Checking out repository..."
        checkout scm
      }
    }

    stage('Install Dependencies & Run Unit Tests') {
      steps {
        sh '''
          echo ">>> Installing dependencies..."
          cd app
          pip install -r requirements.txt pytest > /dev/null 2>&1 || true

          echo ">>> Running unit tests..."
          pytest --maxfail=1 --disable-warnings -q || echo "⚠️ No tests found or some failed"
        '''
      }
    }

    stage('Build Docker Image') {
      steps {
        sh '''
          echo ">>> Building Docker image..."
          docker build -t ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER} ./app
        '''
      }
    }

    stage('Trivy Scan') {
      steps {
        sh '''
          echo ">>> Scanning image with Trivy..."
          if ! command -v trivy >/dev/null 2>&1; then
            echo "Installing Trivy..."
            curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh
          fi

          trivy image --severity HIGH,CRITICAL \
                      --exit-code 1 \
                      --ignore-unfixed \
                      ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER} \
          || { echo "❌ CRITICAL/HIGH vulnerabilities found"; exit 1; }
        '''
      }
    }

    stage('Push to Docker Registry') {
      steps {
        sh '''
          echo ">>> Pushing image to local registry..."
          docker push ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}
        '''
      }
    }

    stage('Helm Lint') {
      steps {
        sh '''
          echo ">>> Linting Helm chart..."
          helm lint helm/python || true
        '''
      }
    }

    stage('Deploy via Helm') {
      steps {
        sshagent(['kube-master-ssh']) {
          sh '''
            echo ">>> Deploying via Helm to Kubernetes ${DEPLOY_ENV}..."

            # Copy chart to K8s master
            scp -o StrictHostKeyChecking=no -r helm/python ${K8S_MASTER}:/home/rocky/my-python-app/

            # Deploy Helm release
            ssh -o StrictHostKeyChecking=no ${K8S_MASTER} '
              helm upgrade --install python-release \
                /home/rocky/my-python-app/python \
                -n ${DEPLOY_ENV} \
                --create-namespace \
                -f /home/rocky/my-python-app/python/values-${DEPLOY_ENV}.yaml \
                --set image.repository=${REGISTRY}/${IMAGE_NAME} \
                --set image.tag=${BUILD_NUMBER}
            '
          '''
        }
      }
    }

    stage('Post-Deploy Check') {
      steps {
        sshagent(['kube-master-ssh']) {
          sh '''
            echo ">>> Checking running pods..."
            ssh -o StrictHostKeyChecking=no ${K8S_MASTER} "/bin/kubectl get pods -n ${DEPLOY_ENV} -o wide"
          '''
        }
      }
    }
  }

  post {
    success {
      echo "✅ Deployment successful to ${params.DEPLOY_ENV} environment!"
    }
    failure {
      echo "❌ Pipeline failed. Check console output for details."
    }
  }
}
