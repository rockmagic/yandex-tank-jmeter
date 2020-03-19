# Yandex.Tank with jmeter and some plugins

FROM ubuntu:latest

# You may specify tag instead of branch to build for specific tag
ARG BRANCH=master
ARG JMETER_VERSION=5.2.1
ARG TELEGRAF_VERSION=1.13.4-1
ARG JVM="openjdk-11-jdk"


LABEL Description="Yandex.Tank with Apache Jmeter" \
    YandexTank.version="${VERSION}" \
    Telegraf.version="${TELEGRAF_VERSION}" \
    Jmeter.version="${JMETER_VERSION}"

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update -q && \
    apt-get install --no-install-recommends -yq \
        sudo     \
        vim      \
        wget     \
        curl     \
        less     \
        iproute2 \
        software-properties-common \
        telnet   \
        atop     \
        openssh-client \
        git            \
        ${JVM} \
        python-pip  && \
    add-apt-repository ppa:yandex-load/main -y && \
    apt-get update -q && \
    apt-get install -yq \
        phantom \
        phantom-ssl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* /tmp/* /var/tmp/*

RUN wget --progress=dot:giga https://dl.influxdata.com/telegraf/releases/telegraf_${TELEGRAF_VERSION}_amd64.deb && \
    dpkg -i telegraf_${TELEGRAF_VERSION}_amd64.deb && \
    rm telegraf_${TELEGRAF_VERSION}_amd64.deb

ENV BUILD_DEPS="python-dev build-essential gfortran libssl-dev libffi-dev"
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -yq --no-install-recommends ${BUILD_DEPS} && \
    pip install --upgrade setuptools && \
    pip install --upgrade pip &&        \
    pip install https://api.github.com/repos/yandex/yandex-tank/tarball/${BRANCH} && \
    apt-get autoremove -y ${BUILD_DEPS} && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* /tmp/* /var/tmp/* /root/.cache/*

ENV JMETER_PLUGINS="jpgc-csl,jpgc-tst,jpgc-dummy,jmeter-jdbc,jpgc-functions,jpgc-casutg,bzm-http2"
ENV JMETER_HOME=/usr/local/apache-jmeter-"${JMETER_VERSION}"
RUN wget https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz --progress=dot:giga && \
    tar -xzf apache-jmeter-${JMETER_VERSION}.tgz -C /usr/local && \
    rm apache-jmeter-${JMETER_VERSION}.tgz

RUN cd ${JMETER_HOME}/lib/ && \
    for lib in \
        "kg/apc/cmdrunner/2.2/cmdrunner-2.2.jar" \
        "org/postgresql/postgresql/42.1.4/postgresql-42.1.4.jar"; \
    do local_name=$(echo "$lib" | awk -F'/' '{print $NF}') ; \
        wget "https://search.maven.org/remotecontent?filepath=${lib}" -O "${local_name}" --progress=dot:mega ;\
    done && \
    cd ${JMETER_HOME}/lib/ext && \
    wget 'http://search.maven.org/remotecontent?filepath=kg/apc/jmeter-plugins-manager/1.3/jmeter-plugins-manager-1.3.jar' -O jmeter-plugins-manager-1.3.jar --progress=dot:mega && \
    java -cp ${JMETER_HOME}/lib/ext/jmeter-plugins-manager-1.3.jar org.jmeterplugins.repository.PluginManagerCMDInstaller && \
    ${JMETER_HOME}/bin/PluginsManagerCMD.sh install "${JMETER_PLUGINS}" && \
    mkdir -p /etc/yandex-tank && \
    printf "jmeter:\n  jmeter_path: ${JMETER_HOME}/bin/jmeter\n  jmeter_ver: ${JMETER_VERSION}\n" > /etc/yandex-tank/10-jmeter.yaml
ENV PATH ${PATH}:${JMETER_HOME}/bin

COPY files/bashrc /root/.bashrc
COPY files/inputrc /root/.inputrc
COPY files/jmeter-large "${JMETER_HOME}"/bin/jmeter-large

VOLUME ["/var/loadtest"]
WORKDIR /var/loadtest
ENTRYPOINT ["/usr/local/bin/yandex-tank"]
