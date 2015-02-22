FROM ubuntu:trusty
MAINTAINER mallocworks@gmail.com

RUN apt-get update -y
RUN apt-get install -y --force-yes \
  libreadline6 libreadline6-dev software-properties-common sudo

RUN add-apt-repository -y ppa:git-core/ppa
RUN add-apt-repository -y ppa:ondrej/mysql-5.6
RUN add-apt-repository -y ppa:ondrej/php5-5.6
RUN add-apt-repository -y ppa:nginx/stable

RUN apt-get update -y
RUN apt-get install -y --force-yes \
  git-core curl zip unzip wget nginx mysql-client \
  php5-fpm php5-cli php5-json php5-mcrypt php5-mysql php5-gd php5-curl \
  php5-imap php5-tidy php5-intl php5-sqlite

RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php5/fpm/php.ini
RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php5/cli/php.ini
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php5/fpm/php.ini

RUN rm -rf /etc/nginx/sites-enabled/default
ADD scripts/site-default /etc/nginx/sites-available/default
RUN ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

RUN mkdir -p /var/www/html
ADD scripts/phpinfo.php /var/www/html/
RUN chown -R www-data:www-data /var/www
RUN chmod 644 $(find /var/www -type f)
RUN chmod 755 $(find /var/www -type d)

ADD scripts/nginx-start /usr/local/bin/
RUN chmod +x /usr/local/bin/nginx-start
RUN service nginx restart

CMD nginx-start

EXPOSE 80

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
