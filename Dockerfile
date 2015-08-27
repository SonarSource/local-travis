FROM maven:3.2-jdk-7

RUN apt-get update && apt-get install -y \
  bzip2 \
  nodejs \
  npm \
  xvfb \
  vim \
  jq

RUN ln -s /usr/bin/nodejs /usr/bin/node

# Install firefox 31
RUN (curl -SL http://ftp.mozilla.org/pub/mozilla.org/firefox/releases/31.0/linux-x86_64/en-US/firefox-31.0.tar.bz2 | tar xj -C /opt) \
	&& ln -sf /opt/firefox/firefox /usr/bin/firefox

ENV CI true
ENV TRAVIS true
ENV RAILS_ENV test
ENV PATH ~/.local/bin:$PATH
ENV TRAVIS_COMMIT master

WORKDIR /home/travis
CMD ["/bin/bash"]
