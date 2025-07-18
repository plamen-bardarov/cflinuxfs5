ARG base
FROM $base
ARG locales
ARG packages
ARG package_args='--allow-downgrades --allow-remove-essential --allow-change-held-packages --no-install-recommends'
ARG user_id=2000
ARG group_id=2000

# Use new deb822 sources
COPY packages/ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources

RUN echo "debconf debconf/frontend select noninteractive" | debconf-set-selections && \
  export DEBIAN_FRONTEND=noninteractive && \
  apt-get -y $package_args update && \
  apt-get -y $package_args dist-upgrade && \
  apt-get -y $package_args install $packages && \
  apt-get clean && \
  find /usr/share/doc/*/* ! -name copyright | xargs rm -rf

RUN sed -i s/#PermitRootLogin.*/PermitRootLogin\ no/ /etc/ssh/sshd_config && \
  sed -i s/#PasswordAuthentication.*/PasswordAuthentication\ no/ /etc/ssh/sshd_config

RUN echo 'LANG="en_US.UTF-8"' > /etc/default/locale && \
  echo "$locales" | grep -f - /usr/share/i18n/SUPPORTED | cut -d " " -f 1 | xargs locale-gen && \
  dpkg-reconfigure -fnoninteractive -pcritical locales tzdata libc6

RUN useradd -u ${user_id} -mU -s /bin/bash vcap && \
  mkdir /home/vcap/app && \
  chown vcap:vcap /home/vcap/app && \
  ln -s /home/vcap/app /app

RUN printf '\n%s\n' >> "/etc/ssl/openssl.cnf" \
  '# Allow user-set openssl.cnf' \
  '.include /tmp/app/openssl.cnf' \
  '.include /home/vcap/app/openssl.cnf'

USER ${user_id}:${group_id}
