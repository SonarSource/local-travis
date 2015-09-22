FROM maven:3.2-jdk-7

RUN apt-get update && apt-get install -y \
  bzip2 \
  nodejs \
  npm \
  xvfb \
  vim \
  jq

# grab gosu for easy step-down from root
RUN gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.4/gosu-$(dpkg --print-architecture)" \
    && curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.4/gosu-$(dpkg --print-architecture).asc" \
    && gpg --verify /usr/local/bin/gosu.asc \
    && rm /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu

RUN ln -s /usr/bin/nodejs /usr/bin/node

# Install firefox 31
RUN (curl -SL http://ftp.mozilla.org/pub/mozilla.org/firefox/releases/31.0/linux-x86_64/en-US/firefox-31.0.tar.bz2 | tar xj -C /opt) \
	&& ln -sf /opt/firefox/firefox /usr/bin/firefox

ENV DEV_UID=1000 \
    DEV_GID=1000

ENV CI true
ENV TRAVIS true
ENV RAILS_ENV test
ENV PATH ~/.local/bin:$PATH
ENV TRAVIS_COMMIT master

WORKDIR /home/travis

COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["/bin/bash"]
