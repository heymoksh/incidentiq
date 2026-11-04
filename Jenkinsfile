// incidentIQ - Jenkins CI/CD pipeline
// GitHub -> Jenkins (on AWS EC2) -> Docker build & test -> deploy container on EC2
// Team: Moksh Jain (RA2311003010474), Sanvi Soneji (RA2311003010444)
pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '10'))
  }

  triggers { pollSCM('H/2 * * * *') }

  environment {
    APP       = 'incidentiq'
    HOST      = 'host.docker.internal'
    LIVE_PORT = '80'
    TEST_PORT = '8081'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
        script {
          env.TAG = "v${env.BUILD_NUMBER}-" + sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
        }
        sh 'git log -1 --pretty="Commit %h by %an: %s"'
      }
    }

    stage('Unit Tests') {
      steps {
        sh '''
          docker run --rm -u 1000:1000 -e npm_config_cache=/tmp/.npm -v "$WORKSPACE/app:/app" -w /app node:20-alpine \
            sh -c "npm ci --no-audit --no-fund && npm test"
        '''
      }
    }

    stage('Build Docker Image') {
      steps {
        sh '''
          docker build -t $APP:$TAG -t $APP:latest app
          docker images $APP --format "table {{.Repository}}\\t{{.Tag}}\\t{{.Size}}\\t{{.CreatedSince}}"
        '''
      }
    }

    stage('Test Container') {
      steps {
        sh '''
          docker rm -f $APP-test >/dev/null 2>&1 || true
          docker run -d --name $APP-test -p $TEST_PORT:3000 -e APP_VERSION=$TAG -e DATA_FILE=/tmp/test.json $APP:$TAG
          for i in $(seq 1 20); do curl -fs http://$HOST:$TEST_PORT/health && break; sleep 2; done
          echo
          curl -fs http://$HOST:$TEST_PORT/health | grep -q '"status":"ok"'
          curl -fs -X POST -H "Content-Type: application/json" \
            -d '{"title":"Smoke test incident","service":"Website","reporter":"Jenkins"}' \
            http://$HOST:$TEST_PORT/api/incidents | grep -q '"id":"INC-'
          echo "Smoke test passed"
        '''
      }
      post { always { sh 'docker rm -f $APP-test >/dev/null 2>&1 || true' } }
    }

    stage('Deploy to EC2') {
      steps {
        sh '''
          docker volume create $APP-data >/dev/null
          docker rm -f $APP >/dev/null 2>&1 || true
          docker run -d --name $APP --restart unless-stopped -p $LIVE_PORT:3000 \
            -e APP_VERSION=$TAG -v $APP-data:/data $APP:$TAG
          for i in $(seq 1 20); do curl -fs http://$HOST:$LIVE_PORT/health && break; sleep 2; done
          echo
          docker ps --filter name=^/$APP$ --format "table {{.Names}}\\t{{.Image}}\\t{{.Status}}\\t{{.Ports}}"
        '''
      }
    }

    stage('Verify Deployment') {
      steps {
        sh '''
          curl -fs http://$HOST:$LIVE_PORT/health | tee health.json
          echo
          grep -q "$TAG" health.json
          echo "incidentIQ $TAG is live on port $LIVE_PORT"
        '''
      }
    }
  }

  post {
    success { echo "SUCCESS: incidentIQ ${env.TAG} deployed" }
    failure { echo 'FAILED: the previous version keeps running if the new image failed its tests' }
    always  { sh 'docker image prune -f >/dev/null 2>&1 || true' }
  }
}
