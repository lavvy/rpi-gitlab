#!/bin/bash
set -e

# set PATH (fixes cron job PATH issues)
cat >> ${GITLAB_HOME}/.profile <<EOF
PATH=/usr/local/sbin:/usr/local/bin:\$PATH
EOF

rm -rf ${GITLAB_HOME}/.ssh
sudo -HEu ${GITLAB_USER} mkdir -p ${GITLAB_DATA_DIR}/.ssh
sudo -HEu ${GITLAB_USER} ln -s ${GITLAB_DATA_DIR}/.ssh ${GITLAB_HOME}/.ssh

# create the data store
sudo -HEu ${GITLAB_USER} mkdir -p ${GITLAB_DATA_DIR}

# configure git for the 'git' user
sudo -HEu ${GITLAB_USER} git config --global core.autocrlf input

# install gitlab-shell
echo "Cloning gitlab-shell v.${GITLAB_SHELL_VERSION}..."
sudo -u git -H git clone -q -b v${GITLAB_SHELL_VERSION} --depth 1 \
	https://github.com/gitlabhq/gitlab-shell.git ${GITLAB_SHELL_INSTALL_DIR}

cd ${GITLAB_SHELL_INSTALL_DIR}
sudo -u git -H cp -a config.yml.example config.yml
sudo -u git -H ./bin/install

# shallow clone gitlab-ce
echo "Cloning gitlab-ce v.${GITLAB_VERSION}..."
sudo -HEu ${GITLAB_USER} git clone -q -b v${GITLAB_VERSION} --depth 1 \
	https://github.com/gitlabhq/gitlabhq.git ${GITLAB_INSTALL_DIR}

cd ${GITLAB_INSTALL_DIR}

# remove HSTS config from the default headers, we configure it in nginx
sed "/headers\['Strict-Transport-Security'\]/d" -i app/controllers/application_controller.rb

# copy default configurations
cp lib/support/nginx/gitlab /etc/nginx/sites-enabled/gitlab
sudo -HEu ${GITLAB_USER} cp config/gitlab.yml.example config/gitlab.yml
sudo -HEu ${GITLAB_USER} cp config/resque.yml.example config/resque.yml
sudo -HEu ${GITLAB_USER} cp config/database.yml.mysql config/database.yml
sudo -HEu ${GITLAB_USER} cp config/unicorn.rb.example config/unicorn.rb
sudo -HEu ${GITLAB_USER} cp config/initializers/rack_attack.rb.example config/initializers/rack_attack.rb
sudo -HEu ${GITLAB_USER} cp config/initializers/smtp_settings.rb.sample config/initializers/smtp_settings.rb

# symlink log -> ${GITLAB_LOG_DIR}/gitlab
rm -rf log
ln -sf ${GITLAB_LOG_DIR}/gitlab log

# create required tmp directories
sudo -HEu ${GITLAB_USER} mkdir -p tmp/pids/ tmp/sockets/
chmod -R u+rwX tmp

# create symlink to assets in tmp/cache
rm -rf tmp/cache
sudo -HEu ${GITLAB_USER} ln -s ${GITLAB_DATA_DIR}/tmp/cache tmp/cache

# create symlink to assets in public/assets
rm -rf public/assets
sudo -HEu ${GITLAB_USER} ln -s ${GITLAB_DATA_DIR}/tmp/public/assets public/assets

# create symlink to uploads directory
rm -rf public/uploads
sudo -HEu ${GITLAB_USER} ln -s ${GITLAB_DATA_DIR}/uploads public/uploads

# create symlink to .secret in GITLAB_DATA_DIR
rm -rf .secret
sudo -HEu ${GITLAB_USER} ln -sf ${GITLAB_DATA_DIR}/.secret
