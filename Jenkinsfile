pipeline {
    agent any

    environment {
        BIOMETRIC_IMAGE = "votechain/biometric"
        AUTH_IMAGE      = "votechain/auth"
        VOTE_IMAGE      = "votechain/vote"
        IMAGE_TAG       = "${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
                sh 'echo "Code checked out successfully"'
                sh 'ls -la'
            }
        }

        stage('Verify Tools') {
            steps {
                sh 'docker --version'
                sh 'docker compose version'
                sh 'echo "All tools available"'
            }
        }

        stage('Build Images') {
            parallel {
                stage('Build Biometric') {
                    steps {
                        sh 'docker build -t ${BIOMETRIC_IMAGE}:${IMAGE_TAG} ./services/biometric'
                        sh 'docker tag ${BIOMETRIC_IMAGE}:${IMAGE_TAG} ${BIOMETRIC_IMAGE}:latest'
                    }
                }
                stage('Build Auth') {
                    steps {
                        sh 'docker build -t ${AUTH_IMAGE}:${IMAGE_TAG} ./services/auth'
                        sh 'docker tag ${AUTH_IMAGE}:${IMAGE_TAG} ${AUTH_IMAGE}:latest'
                    }
                }
                stage('Build Vote') {
                    steps {
                        sh 'docker build -t ${VOTE_IMAGE}:${IMAGE_TAG} ./services/vote'
                        sh 'docker tag ${VOTE_IMAGE}:${IMAGE_TAG} ${VOTE_IMAGE}:latest'
                    }
                }
            }
        }
	stage('Security Scan') {
		parallel {
		stage('Scan Biometric') {
			steps {
			sh 'GRYPE_DB_CACHE_DIR=/tmp/grype-db grype votechain/biometric:${IMAGE_TAG} --fail-on critical -o table'
				}
			}
		stage('Scan Auth') {
			steps {
			sh 'GRYPE_DB_CACHE_DIR=/tmp/grype-db grype votechain/auth:${IMAGE_TAG} --fail-on critical -o table'
				}
			}
		stage('Scan Vote') {
			steps {
			sh 'GRYPE_DB_CACHE_DIR=/tmp/grype-db grype votechain/vote:${IMAGE_TAG} --fail-on critical -o table'
				}
			}
		}	
	}
	stage('Health Check') {
		steps {
			sh '''
			docker compose down || true
			docker compose up -d
			echo "Waiting for services to become healthy..."
			sleep 40
			docker compose ps
			'''
			sh '''
			docker inspect --format="{{.State.Health.Status}}" votechain-biometric | grep healthy
			docker inspect --format="{{.State.Health.Status}}" votechain-auth | grep healthy
			docker inspect --format="{{.State.Health.Status}}" votechain-vote | grep healthy
			'''
			}
		}
	}
	post {
		success {
			echo "Pipeline passed. All services built, scanned and healthy."
			}
		failure {
			echo "Pipeline failed. Check logs above for details."
			sh 'docker compose down || true'
			}
		always {
			sh 'docker image prune -f || true'
		}
	}
}

