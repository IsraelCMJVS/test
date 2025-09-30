pipeline {
  agent any
  environment {
    OCP_SERVER    = 'https://api.ocpprod.pjedomex.gob.mx:6443'   // <-- pon tu API
    OCP_NAMESPACE = 'demo-cicd'
    APP_NAME      = 'demo-app'
    IMAGE_TAG     = 'latest'                        // usamos latest para gatillar el trigger
  }
  options {
    timestamps()
    ansiColor('xterm')
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }
  stages {

    stage('Checkout') {
      steps {
        checkout scm
        script {
          // opcional: etiqueta con el short sha por si quieres tener histórico de tags
          env.GIT_SHORT = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
        }
      }
    }

    stage('Login OpenShift') {
      steps {
        withCredentials([string(credentialsId: 'ocp-token-demo', variable: 'OCP_TOKEN')]) {
          sh '''
            set -e
            oc logout || true
            oc login --token="$OCP_TOKEN" --server="$OCP_SERVER" --insecure-skip-tls-verify=true
            oc project '"$OCP_NAMESPACE"'
            oc whoami
          '''
        }
      }
    }

    stage('Apply Build Resources (IS + BC)') {
      steps {
        sh '''
          set -e
          # Aplica/actualiza ImageStream y BuildConfig
          oc apply -f openshift/ocp-bc.yaml -n "$OCP_NAMESPACE"

          # Validación rápida
          oc get is "$APP_NAME" -n "$OCP_NAMESPACE"
          oc get bc "$APP_NAME" -n "$OCP_NAMESPACE"
        '''
      }
    }

    stage('Binary Build (DockerStrategy)') {
      steps {
        sh '''
          set -e
          # Enviamos TODO el repo como contexto (contiene Dockerfile en raíz)
          # --follow y --wait para ver logs en tiempo real y esperar resultado
          oc start-build "$APP_NAME" \
            --from-dir=. \
            --follow --wait \
            -n "$OCP_NAMESPACE"

          # (Opcional) también podemos etiquetar con el commit
          # oc tag -n "$OCP_NAMESPACE" "$APP_NAME:latest" "$APP_NAME:${GIT_SHORT}" || true
        '''
      }
    }

    stage('Apply Deploy/Service/Route') {
      steps {
        sh '''
          set -e
          oc apply -f openshift/deploy-svc-route.yaml -n "$OCP_NAMESPACE"

          # Espera rollout del Deployment (la anotación de trigger actualizará la imagen al push del IS)
          oc rollout status deploy/"$APP_NAME" -n "$OCP_NAMESPACE" --timeout=5m
        '''
      }
    }

    stage('Smoke test (Route)') {
      steps {
        script {
          def host = sh(script: "oc get route ${APP_NAME} -n ${OCP_NAMESPACE} -o jsonpath='{.spec.host}'", returnStdout: true).trim()
          echo "Route: https://${host} (edge TLS) o http://${host}"
          // Probamos HTTP (si edge TLS, también responde en http->terminación en router)
          sh "curl -sS --max-time 10 http://${host}/ | head -n 5 || true"
        }
      }
    }
  }
  post {
    success {
      script {
        def host = sh(script: "oc get route ${APP_NAME} -n ${OCP_NAMESPACE} -o jsonpath='{.spec.host}'", returnStdout: true).trim()
        echo "✅ Despliegue listo: http://${host}"
      }
    }
    failure {
      echo '❌ Falló el pipeline. Revisa los logs de build (etapa Binary Build) y el rollout.'
      sh 'oc get events -n "$OCP_NAMESPACE" --sort-by=.lastTimestamp | tail -n 50 || true'
    }
    always {
      sh 'oc get pods -o wide -n "$OCP_NAMESPACE" || true'
    }
  }
}
