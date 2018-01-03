FROM honto/java:8u102
MAINTAINER lan-nt<fjn_lan_nt@stg.honto.jp>
RUN apk add --update curl && \
    curl --create-dirs -o /usr/local/bin/embulk -L "http://dl.embulk.org/embulk-latest.jar" && \
    chmod +x /usr/local/bin/embulk && \
    mkdir /etc/embulk
VOLUME /etc/embulk
RUN curl --create-dirs -o /usr/lib/jdbc/ojdbc7_g-12.1.0.2.jar -L "https://storage.googleapis.com/honto-dev-server-resources/lib/ojdbc7_g-12.1.0.2.jar"
ADD ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
CMD /entrypoint.sh "embulk-input-jdbc embulk-input-oracle embulk-output-file liquid"
