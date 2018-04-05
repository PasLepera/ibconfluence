FROM paslepera/iborajre8:0.1
LABEL maintainer="Pasquale Lepera <pasquale@ibuildings.it>"

# https://confluence.atlassian.com/doc/confluence-home-and-other-important-directories-590259707.html
ENV CONFLUENCE_HOME /var/local/atlassian/confluence
ENV CONFLUENCE_INSTALL_DIR /usr/local/atlassian/confluence
ENV RUN_USER confluence
ENV RUN_GROUP confluence

VOLUME ["${CONFLUENCE_HOME}"]

# Expose HTTP and Synchrony ports
EXPOSE 8090
EXPOSE 8091

WORKDIR $CONFLUENCE_HOME

CMD ["/entrypoint.sh", "-fg"]

RUN deps=" \
	libtcnative-1 xmlstarlet \
	curl \
	wget \
	ca-certificates \
	openssl \
	" \
	&& apt-get update -qq \
	&& apt-get install -y $deps --no-install-recommends \
	&& useradd --create-home --shell /bin/bash ${RUN_USER} \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/ /tmp/* /var/tmp/* \
    && mkdir -p ${CONFLUENCE_INSTALL_DIR} \
    && chown -R ${RUN_USER}:${RUN_GROUP} ${CONFLUENCE_INSTALL_DIR}/

COPY entrypoint.sh /entrypoint.sh

ARG CONFLUENCE_VERSION=6.8.0
ARG DOWNLOAD_URL=http://www.atlassian.com/software/confluence/downloads/binary/atlassian-confluence-${CONFLUENCE_VERSION}.tar.gz

COPY . /tmp

RUN chmod +x /entrypoint.sh \
    && mkdir -p ${CONFLUENCE_INSTALL_DIR} \
    && curl -L --silent ${DOWNLOAD_URL} > /tmp/atlassian-confluence-${CONFLUENCE_VERSION}.tar.gz \
    && tar -xzf /tmp/atlassian-confluence-${CONFLUENCE_VERSION}.tar.gz --strip-components=1 -C "${CONFLUENCE_INSTALL_DIR}" \
    && chown -R ${RUN_USER}:${RUN_GROUP} ${CONFLUENCE_INSTALL_DIR}/ \
    && sed -i -e 's/-Xms\([0-9]\+[kmg]\) -Xmx\([0-9]\+[kmg]\)/-Xms\${JVM_MINIMUM_MEMORY:=\1} -Xmx\${JVM_MAXIMUM_MEMORY:=\2} \${JVM_SUPPORT_RECOMMENDED_ARGS} -Dconfluence.home=\${CONFLUENCE_HOME}/g' ${CONFLUENCE_INSTALL_DIR}/bin/setenv.sh \
    && sed -i -e 's/port="8090"/port="8090" secure="${catalinaConnectorSecure}" scheme="${catalinaConnectorScheme}" proxyName="${catalinaConnectorProxyName}" proxyPort="${catalinaConnectorProxyPort}"/' ${CONFLUENCE_INSTALL_DIR}/conf/server.xml \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ${CONFLUENCE_INSTALL_DIR}/atlassian-confluence-${CONFLUENCE_VERSION}.tar.gz
