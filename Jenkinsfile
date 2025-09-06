pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID = credentials('aws-creds').AWS_ACCESS_KEY_ID
        AWS_SECRET_ACCESS_KEY = credentials('aws-creds').AWS_SECRET_ACCESS_KEY
        AWS_DEFAULT_REGION = 'us-east-1'
        GITHUB_REPO = 'yourusername/my-java-app'
        APP_NAME = 'my-app'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build with Maven') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    dockerImage = docker.build("${APP_NAME}:${env.BUILD_ID}")
                }
            }
        }

        stage('Provision Infrastructure with Terraform') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                    sh 'terraform apply -auto-approve -var "aws_access_key=${AWS_ACCESS_KEY_ID}" -var "aws_secret_key=${AWS_SECRET_ACCESS_KEY}"'
                }
                script {
                    env.ECR_REPO = sh(script: "cd terraform && terraform output -raw ecr_repo_url", returnStdout: true).trim()
                    env.EC2_IP = sh(script: "cd terraform && terraform output -raw instance_public_ip", returnStdout: true).trim()
                }
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                sh """
                aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}
                docker tag ${APP_NAME}:${env.BUILD_ID} ${ECR_REPO}:latest
                docker push ${ECR_REPO}:latest
                """
            }
        }

        stage('Deploy with Ansible') {
            steps {
                dir('ansible') {
                    ansiblePlaybook(
                        playbook: 'deploy.yml',
                        inventory: "app_server ansible_host=${EC2_IP} ansible_user=ec2-user ansible_ssh_private_key_file=/var/lib/jenkins/.ssh/your-key-pair.pem",
                        extras: "-e ecr_repo=${ECR_REPO}"
                    )
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline completed.'
        }
    }
}