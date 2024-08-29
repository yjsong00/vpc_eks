/* Jenkinsfile */
def imageTag
node {

    def app

    stage('Clone repository') {
        /* Let's make sure we have the repository cloned to our workspace */

        checkout scm
    }

    stage('Build image') {
        /* This builds the actual image; synonymous to
         * docker build on the command line */

        app = docker.build("test")
    }

    stage('Test image') {
        /* Run a test framework against our image. */

        app.inside {
            sh 'echo "Tests passed"'
        }
    }

    stage('Push image') {
        /* Finally, we'll push the image with two tags:
         * First, the incremental build number from Jenkins
         * Second, the 'latest' tag.
         * Pushing multiple tags is cheap, as all the layers are reused. */
        imageTag = sh(script: "head -n 1 Dockerfile | sed 's/#//'", returnStdout: true).trim()
        docker.withRegistry('https://865577889736.dkr.ecr.ap-northeast-2.amazonaws.com', 'ecr:REGION:ecrUser') {
        /*    app.push("${env.BUILD_NUMBER}") */
            app.push("${imageTag}")
            app.push("latest")
        }
        echo "Pushed image with tag: ${imageTag}"
    }
}

pipeline {
    agent any
    environment {
        GITNAME = 'pcmin929'
        GITEMAIL = 'pcmin929@gmail.com'
        GITWEBADD = 'git@github.com:pcmin929/fast-code.git'
        GITSSHADD = 'git@github.com:pcmin929/deployment.git'
        GITCREDENTIAL = 'git_cre'
        DOCKERHUB = '865577889736.dkr.ecr.ap-northeast-2.amazonaws.com/fast'
        DOCKERHUBCREDENTIAL = 'ecr_cre'
    }
    stages {
        stage('Checkout Github') {
            
            steps {
            //    slackSend (
            //        channel: '#dep02', 
            //        color: '#FFFF00', 
            //        message: "STARTED: ${currentBuild.number}"
            //    )
            //    checkout([$class: 'GitSCM', branches: [[name: '*/main']], extensions: [],
            //    userRemoteConfigs: [[credentialsId: GITCREDENTIAL, url: GITWEBADD]]])
                  checkout scm
            }
            post {
                failure {
                    sh "echo clone failed"
                }
                success {
                    sh "echo clone success"
                }
            }
        }
        stage('docker image build') {
            steps {
                sh "docker build -t ${DOCKERHUB}:${currentBuild.number} ."
                sh "docker build -t ${DOCKERHUB}:latest ."
                // currentBuild.number 젠킨스가 제공하는 빌드넘버 변수
                // oolralra/fast:<빌드넘버> 와 같은 이미지가 만들어질 예정.
                
            }
            post {
                failure {
                    sh "echo image build failed"
                }
                success {
                    sh "echo image build success"
                }
            }
        }
        stage('docker image push') {
            steps {
                withDockerRegistry(credentialsId: ecr:ap-northeast-2:ecr_cre, url: '${DOCKERHUB}') {
                    sh "docker push ${DOCKERHUB}:${currentBuild.number}"
                    sh "docker push ${DOCKERHUB}:latest"
                }
            }
            post {
                failure {
                    sh "docker image rm -f ${DOCKERHUB}:${currentBuild.number}"
                    sh "docker image rm -f ${DOCKERHUB}:latest"
                    sh "echo push failed"
                    // 성공하든 실패하든 로컬에 있는 도커이미지는 삭제
                }
                success {
                    sh "docker image rm -f ${DOCKERHUB}:${currentBuild.number}"
                    sh "docker image rm -f ${DOCKERHUB}:latest"
                    sh "echo push success"
                    // 성공하든 실패하든 로컬에 있는 도커이미지는 삭제
                }
            }
        }
        // stage('EKS manifest file update') {
        //     steps {
        //         git credentialsId: GITCREDENTIAL, url: GITSSHADD, branch: 'main'
        //         sh "git config --global user.email ${GITEMAIL}"
        //         sh "git config --global user.name ${GITNAME}"
        //         sh "sed -i 's@${DOCKERHUB}:.*@${DOCKERHUB}:${currentBuild.number}@g' fast.yml"

        //         sh "git add ."
        //         sh "git branch -M main"
        //         sh "git commit -m 'fixed tag ${currentBuild.number}'"
        //         sh "git remote remove origin"
        //         sh "git remote add origin ${GITSSHADD}"
        //         sh "git push origin main"
        //     }
        //     post {
        //         failure {
        //             sh "echo manifest update failed"
        //         }
        //         success {
        //             sh "echo manifest update success"
        //         }
        //     }
        // }
        

    }
}