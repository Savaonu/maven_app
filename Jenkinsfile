pipeline {
    agent {
            label "lin_node"
        }
    environment {
        DOCKER_HUB_CRED = credentials('docker_cred')
        ARTIFACTORY_CRED = credentials('Artifactory_admin')
    }
    parameters {
        string(name: 'image_name', defaultValue: 'maven_image', description: 'Name of the image')
        string(name: 'container_name', defaultValue: 'my_maven_app', description: 'Name of the container')
        string(name: 'sonar_token', defaultValue: 'aca9fee4aae893fa63b46476fb1938ddaac62ed9', description: 'The token from Sonarqube')
        string(name: 'sonar_srv', defaultValue: 'http://172.30.68.55:9000', description: 'The Sonarqube server')
        string(name: 'art_repo', defaultValue: '${params.art_repo}', description: 'Artifactory docker registry')

    }

    stages {
        stage('Fetch Git') {
            steps {
                // Get some code from a GitHub repository
                git 'https://github.com/Savaonu/maven_app'
            }
        }
        
        stage('Maven build') {
            agent {
                label "slave_maven_build"
            }
            steps {
                script {
        
                    //sh "mvn deploy -f artifactory-maven-plugin-example/ -s artifactory-maven-plugin-example/settings.xml"
                    def mvnHome = tool 'Maven 3.6.3'
                    sh "'${mvnHome}/bin/mvn' -f app/ package deploy -f app/ -Dusername=${ARTIFACTORY_CRED_USR} -Dpassword=${ARTIFACTORY_CRED_PSW} -D${env.BUILD_NUMBER}"
                }
            }
        }
        
        
        stage('Build Image') {
            agent {
                label "slave_maven_build"
            }
            steps {
                // Build Image
                sh "docker build -t ${params.art_repo}/${params.image_name}:${env.BUILD_NUMBER} . --label \"type=${params.image_name}\""
            }
        }
        stage('SonarQube analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    // Sonarqube check
                    sh "mvn -f app/ sonar:sonar -Dsonar.host.url=${params.sonar_srv} -Dsonar.login=${params.sonar_token}"
                }
            }
        }
        stage("Quality gate") {
            steps {
                // Check if the analysis is good 
                waitForQualityGate abortPipeline: true
            }
        }
        stage('Deploy to Artifactory'){
            agent {
                label "slave_maven_build"
            }
            steps {
                // Push to Dockerhub repo
               // withCredentials([usernamePassword(credentialsId: 'Artifactory_admin', passwordVariable: 'repo_passw', usernameVariable: 'repo_username')]) {
                    sh "echo \"${ARTIFACTORY_CRED_PSW}\" | docker login -u \"${ARTIFACTORY_CRED_USR}\" ${params.art_repo} --password-stdin"
                    sh "docker push ${params.art_repo}/${params.image_name}:${env.BUILD_NUMBER}"
                //}
            }
        }
        stage('Clean images'){
            agent {
                label "slave_maven_build"
            }
                    steps {
                        // Delete the image pushed to Artifactory
                        sh "docker rmi --force ${params.art_repo}/${params.image_name}:${env.BUILD_NUMBER}"
                        sh "docker rmi --force ${params.image_name}:${env.BUILD_NUMBER}"
                    }
                }
        stage('Deploy to App'){
            agent {
                label "slave_maven_deploy"
            }
            steps {
                // Clean old Container
                sh "chmod +x ./cleanup.sh && ./cleanup.sh "

                // Push to Artifactory docker registry
                //withCredentials([usernamePassword(credentialsId: 'ae4a797f-6a03-4dc7-874f-c6683cc2fcba', passwordVariable: 'repo_passw', usernameVariable: 'repo_username')]) {
                    sh "echo \"${ARTIFACTORY_CRED_PSW}\" | docker login -u \"${ARTIFACTORY_CRED_USR}\" ${params.art_repo} --password-stdin"
                   // sh "docker tag $image_name savaonu/$image_name"
                    sh "docker pull ${params.art_repo}/${params.image_name}:${env.BUILD_NUMBER}"
                     // Create container
                    sh "docker run -p 8089:8080 -d --name ${params.container_name} ${params.art_repo}/${params.image_name}:${env.BUILD_NUMBER}"
                //}
            }
        }

        stage('Email'){
                    //agent {
                        // Run on windows node 
                      //  label "lin_node"
                    //}
                    steps {
                        // Info via email from windows node
                        emailext body: "<b>Project build successful</b><br>Project: ${env.JOB_NAME} <br>Build Number: ${env.BUILD_NUMBER} <br> URL de build: ${env.BUILD_URL}", from: 'jenkins@test.com', mimeType: 'text/html', replyTo: '', subject: "SUCCESSFUL CI: Project name -> ${env.JOB_NAME}", to: "alexandru.sava@accesa.eu";
                    }
        }
    }
    post {
         failure {
                // Info via email about failed job
             sendEmail("Failed");
         }
        unsuccessful {  
              // Info via email about unsuccessful job 
            sendEmail("Unsuccessful");
        } 
    }
    options {
        // For example, we'd like to make sure we only keep 10 builds at a time, so
        // we don't fill up our storage!
        buildDiscarder(logRotator(numToKeepStr: '10'))

        // And we'd really like to be sure that this build doesn't hang forever, so
        // let's time it out after an hour.
        timeout(time: 5, unit: 'MINUTES')
    }
}
def sendEmail(status) {
    mail body: "<b>Project build </b>" + "<b>$status</b>"   + "<br>Project: ${env.JOB_NAME} <br>Build Number: ${env.BUILD_NUMBER} <br> URL de build: ${env.BUILD_URL}", charset: 'UTF-8', from: 'jenkins@test.com', mimeType: 'text/html', replyTo: '', subject: status + "  CI: Project name -> ${env.JOB_NAME}", to: "alexandru.sava@accesa.eu";
} 