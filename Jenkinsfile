pipeline {
    agent any

    environment {
        PACKAGE_NAME = 'count-files'
        PACKAGE_VERSION = '1.0'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'ls -la'
            }
        }

        stage('Test Script') {
            steps {
                // фикс CRLF (Windows) -> LF, чтобы не было /bin/bash^M
                sh 'sed -i "s/\\r$//" count_files.sh || true'
                sh 'chmod +x count_files.sh'
                sh 'bash -n count_files.sh'
                sh './count_files.sh'
            }
        }

        stage('Build RPM') {
            agent {
                docker {
                    image 'fedora:latest'
                    args '-u root'
                }
            }
            steps {
                sh '''
                    dnf install -y rpm-build rpmdevtools findutils coreutils
                    rpmdev-setuptree

                    mkdir -p ~/rpmbuild/SOURCES/${PACKAGE_NAME}-${PACKAGE_VERSION}
                    cp count_files.sh ~/rpmbuild/SOURCES/${PACKAGE_NAME}-${PACKAGE_VERSION}/
                    sed -i 's/\\r$//' ~/rpmbuild/SOURCES/${PACKAGE_NAME}-${PACKAGE_VERSION}/count_files.sh || true

                    cd ~/rpmbuild/SOURCES
                    tar czvf ${PACKAGE_NAME}-${PACKAGE_VERSION}.tar.gz ${PACKAGE_NAME}-${PACKAGE_VERSION}

                    cp ${WORKSPACE}/packaging/rpm/count-files.spec ~/rpmbuild/SPECS/
                    rpmbuild -ba ~/rpmbuild/SPECS/count-files.spec

                    mkdir -p ${WORKSPACE}/artifacts
                    cp -v ~/rpmbuild/RPMS/noarch/*.rpm ${WORKSPACE}/artifacts/
                '''
                   stash name: 'rpm', includes: 'artifacts/*.rpm', allowEmpty: true
            }
        }

        stage('Build DEB') {
            agent {
                docker {
                    image 'ubuntu:latest'
                    args '-u root'
                }
            }
            steps {
                sh '''
                    apt-get update
                    apt-get install -y build-essential debhelper devscripts

                    mkdir -p build/${PACKAGE_NAME}-${PACKAGE_VERSION}
                    cp count_files.sh build/${PACKAGE_NAME}-${PACKAGE_VERSION}/
                    cp count_files.conf build/${PACKAGE_NAME}-${PACKAGE_VERSION}/
                    cp -r packaging/deb/debian build/${PACKAGE_NAME}-${PACKAGE_VERSION}/

                    # фикс CRLF в debian файлах
                    find build/${PACKAGE_NAME}-${PACKAGE_VERSION} -type f -maxdepth 3 -exec sed -i 's/\\r$//' {} \\; || true

                    cd build/${PACKAGE_NAME}-${PACKAGE_VERSION}
                    dpkg-buildpackage -us -uc -b

                    mkdir -p ${WORKSPACE}/artifacts
                    cp -v ../*.deb ${WORKSPACE}/artifacts/
                    
                '''
                 stash name: 'deb', includes: 'artifacts/*.deb', allowEmpty: true
            }
        }

        stage('Test RPM Installation') {
            agent {
                docker {
                    image 'oraclelinux:8'
                    args '-u root'
                }
            }
            steps {
                sh '''
                   rpm -ivh artifacts/${PACKAGE_NAME}-*.rpm
                   count_files
   	           rpm -e ${PACKAGE_NAME}
                '''

            }
        }

        stage('Test DEB Installation') {
            agent {
                docker {
                    image 'ubuntu:latest'
                    args '-u root'
                }
            }
            steps {
                sh '''
                   dpkg -i artifacts/${PACKAGE_NAME}_*.deb || apt-get install -f -y
                   count_files
                   apt-get remove -y ${PACKAGE_NAME}
                '''
            }
        }
stage('Collect Artifacts') {
    steps {
        sh 'mkdir -p artifacts'
        unstash 'rpm'
        unstash 'deb'
        sh 'ls -la artifacts || true'
    }
}

    }
    
   post {
  always {
    archiveArtifacts artifacts: 'artifacts/*.rpm, artifacts/*.deb', allowEmptyArchive: true
    echo 'Artifacts archived (if any).'
    deleteDir()
  }

  success {
    echo 'Build completed successfully!'
  }

  failure {
    echo 'Build failed!'
  }
}


}