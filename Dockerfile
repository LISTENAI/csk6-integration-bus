FROM ubuntu:22.04 as build

WORKDIR /home/lisa
USER root
RUN useradd -d /home/lisa -s /usr/bin/bash lisa \
    && apt update \
    && apt install --no-install-recommends -y git bash wget xz-utils p7zip-full ca-certificates locales \
    && chown -R lisa:lisa /home/lisa \
    && update-ca-certificates \
    && locale-gen zh_CN.UTF-8 \
    && update-locale

USER lisa
ENV LISA_HOME=/home/lisa/.listenai
ENV LISA_PREFIX=${LISA_HOME}/lisa
ENV PIP_INDEX_URL=https://pypi.org/simple

RUN mkdir -p ${LISA_HOME}/lisa

COPY --chown=lisa:lisa ./csk-integration-bus-linux_x64.tar.xz "${LISA_HOME}/lisa/lisa-zephyr-linux_x64.tar.xz"

ENV LANG=zh_CN.UTF8
RUN tar xJf "${LISA_HOME}/lisa/lisa-zephyr-linux_x64.tar.xz" -C "${LISA_HOME}/lisa" \
    && mkdir "${LISA_HOME}/lisa-zephyr" \
    && mv "${LISA_HOME}/lisa/packages" "${LISA_HOME}/lisa-zephyr"

RUN ${LISA_HOME}/lisa/libexec/lisa zep install \
    && echo "{\"env\":\"csk6\"}" |tee ${LISA_HOME}/lisa-zephyr/config.json \
    && ${LISA_HOME}/lisa/libexec/lisa zep sdk set --default \
    && rm -f "${LISA_HOME}/lisa/lisa-zephyr-linux_x64.tar.xz" \
    && ${LISA_HOME}/lisa/libexec/lisa update zephyr

USER root
RUN echo "LISA_HOME=\"${LISA_HOME}\"" |tee -a /etc/environment \
    && echo "LISA_PREFIX=\"${LISA_PREFIX}\"" |tee -a /etc/environment

FROM ubuntu:22.04
USER root
WORKDIR /home/lisa
RUN useradd -d /home/lisa -s /usr/bin/bash lisa \
    && apt update \
    && apt install --no-install-recommends -y git bash libusb-1.0-0 udev ca-certificates locales \
    && chown -R lisa:lisa /home/lisa

COPY --from=build --chown=lisa:lisa /home/lisa/.listenai /home/lisa/.listenai
COPY --from=build --chown=root:root /etc/environment /etc/environment

RUN ln -s /home/lisa/.listenai/lisa/libexec/lisa /usr/local/bin/lisa \
    && update-ca-certificates \
    && locale-gen zh_CN.UTF-8 \
    && update-locale

USER lisa