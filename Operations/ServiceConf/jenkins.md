# jenkins

/etc/jenkins/jenkins.conf

```bash

```

Jenkinsfile

```Jenkinsfile
pipeline {
    agent {
        kubernetes {
            defaultContainer 'jnlp'
        }
    }

    stages {
        stage('Build') {
            steps {
                container('maven') {
                    sh 'mvn clean package'
                }
            }
        }
        stage('Deploy') {
            steps {
                container('kubectl') {
                    sh 'kubectl apply -f deployment.yaml'
                }
            }
        }
    }
}
```
