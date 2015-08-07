FROM resin/rpi-raspbian
MAINTAINER Marcel Grossmann <whatever4711@gmail.com>

ENV GITLAB_VERSION=7.13.3 \
    GITLAB_SHELL_VERSION=2.6.3 \
    GITLAB_USER="git" \
    GITLAB_HOME="/home/git" \
    GITLAB_LOG_DIR="/var/log/gitlab" \
    SETUP_DIR="/var/cache/gitlab" \
    RAILS_ENV=production

ENV GITLAB_INSTALL_DIR="${GITLAB_HOME}/gitlab" \
    GITLAB_SHELL_INSTALL_DIR="${GITLAB_HOME}/gitlab-shell" \
    GITLAB_DATA_DIR="${GITLAB_HOME}/data" \
    GEM_CACHE_DIR="${SETUP_DIR}/cache"

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv E1DD270288B4E6030699E45FA1715D88E1DF1F24 \
 && echo "deb http://ppa.launchpad.net/git-core/ppa/ubuntu trusty main" >> /etc/apt/sources.list \
 && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 80F70E11F0F0D5F10CB20E62F5DA5F09C3173AA6 \
 && echo "deb http://ppa.launchpad.net/brightbox/ruby-ng/ubuntu trusty main" >> /etc/apt/sources.list \
 && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 8B3981E7A6852F782CC4951600A6F0A3C300EE8C \
 && echo "deb http://ppa.launchpad.net/nginx/stable/ubuntu trusty main" >> /etc/apt/sources.list \
 && apt-get update \
 && apt-get install -yqq supervisor logrotate locales curl \
      nginx openssh-server mysql-client postgresql-client redis-tools \
      git-core ruby2.1 python2.7 python-docutils nodejs \
      libmysqlclient18 libpq5 zlib1g libyaml-0-2 libssl1.0.0 \
      libgdbm3 libreadline6 libncurses5 libffi6 \
      libxml2 libxslt1.1 libcurl3 libicu52

RUN apt-get install -yqq gcc g++ make patch pkg-config cmake \
  libc6-dev ruby2.1-dev libmysqlclient-dev libpq-dev zlib1g-dev libyaml-dev libssl-dev \
  libgdbm-dev libreadline-dev libncurses5-dev libffi-dev \
  libxml2-dev libxslt-dev libcurl4-openssl-dev libicu-dev

# remove the host keys generated during openssh-server installation
RUN rm -rf /etc/ssh/ssh_host_*_key /etc/ssh/ssh_host_*_key.pub

# add ${GITLAB_USER} user
RUN adduser --disabled-login --gecos 'GitLab' ${GITLAB_USER} \
 && passwd -d ${GITLAB_USER}

RUN update-locale LANG=C.UTF-8 LC_MESSAGES=POSIX \
 && locale-gen en_US.UTF-8 \
 && dpkg-reconfigure locales 

RUN ln -s /usr/bin/gem2.1 /usr/bin/gem
RUN ln -s /usr/bin/ruby2.1 /usr/bin/ruby
RUN gem install --no-document bundler

COPY assets/setup/ ${SETUP_DIR}/
RUN bash ${SETUP_DIR}/install.sh

# Clean Up
RUN apt-get purge -y --auto-remove gcc g++ make patch pkg-config cmake \
  libc6-dev ruby2.1-dev \
  libmysqlclient-dev libpq-dev zlib1g-dev libyaml-dev libssl-dev \
  libgdbm-dev libreadline-dev libncurses5-dev libffi-dev \
  libxml2-dev libxslt-dev libcurl4-openssl-dev libicu-dev
RUN rm -rf /var/lib/apt/lists/*

COPY assets/config/ ${SETUP_DIR}/config/
COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

EXPOSE 22/tcp 80/tcp 443/tcp

VOLUME ["${GITLAB_DATA_DIR}", "${GITLAB_LOG_DIR}"]
WORKDIR ${GITLAB_INSTALL_DIR}
ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["app:start"]
