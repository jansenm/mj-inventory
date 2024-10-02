FROM opensuse/tumbleweed

###
###
### Setup a jenkins user
ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000

# https://github.com/jenkinsci/remoting/releases
ARG VERSION=3261.v9c670a_4748a_9

ARG AGENT_WORKDIR=/home/"${user}"/agent

###
### CONFIGURE THE AGENT ENVIRONMENT
ENV TZ=Etc/UTC
ENV LANG C.UTF-8
ENV AGENT_WORKDIR=${AGENT_WORKDIR}

###
### JENKINS USER
RUN groupadd -g "${gid}" "${group}" \
  && useradd -l -c "Jenkins user" -d /home/"${user}" -u "${uid}" -g "${gid}" -m "${user}" || echo "user ${user} already exists."

###
### ADD JENKINS AGENT
ADD --chown="${user}":"${group}" "https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${VERSION}/remoting-${VERSION}.jar" /usr/share/jenkins/agent.jar

# FROM https://github.com/jenkinsci/docker-agent/blob/master/jenkins-agent
COPY jenkins-agent /usr/local/bin/jenkins-agent
RUN chmod 0755 /usr/local/bin/jenkins-agent

###
### SETUP THE JENKINS USER
USER "${user}"
RUN mkdir -p /home/"${user}"/.jenkins && mkdir -p "${AGENT_WORKDIR}"

VOLUME /home/"${user}"/.jenkins
VOLUME "${AGENT_WORKDIR}"
WORKDIR /home/"${user}"
ENV USER=${user}

###
### FINISHED SETTING UP JENKINS
LABEL \
  org.opencontainers.image.vendor="Private" \
  org.opencontainers.image.title="Custom Jenkins Agent / Tumbleweed / Elixir Tools" \
  org.opencontainers.image.description="This is a jenkins agent image to build elixir projects." \
  org.opencontainers.image.version="${VERSION}" \
  org.opencontainers.image.url="https://www.jenkins.io/" \
  org.opencontainers.image.source="https://github.com/jenkinsci/docker-agent" \
  org.opencontainers.image.licenses="MIT"
ENTRYPOINT ["/usr/local/bin/jenkins-agent"]

###
### SETUP DEVELOPMENT TOOLS
USER root
RUN zypper install -y \
      openssh-clients \
      java-21-openjdk-headless \
      git-core \
      erlang-dialyzer \
      elixir \
    && zypper clean

###
### FINISH THE IMAGE
USER ${user}
