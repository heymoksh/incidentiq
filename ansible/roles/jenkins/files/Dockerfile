# Jenkins controller with Docker CLI, kubectl and plugins pre-installed (configured as code) - incidentIQ
FROM jenkins/jenkins:lts-jdk17
USER root
RUN curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-27.3.1.tgz \
      | tar -xz -C /usr/local/bin --strip-components=1 docker/docker \
 && curl -fsSLo /usr/local/bin/kubectl https://dl.k8s.io/release/v1.31.2/bin/linux/amd64/kubectl \
 && chmod +x /usr/local/bin/kubectl
USER jenkins
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false -Xmx768m" \
    CASC_JENKINS_CONFIG=/var/jenkins_home/casc.yaml \
    KUBECONFIG=/var/jenkins_home/.kube/config
