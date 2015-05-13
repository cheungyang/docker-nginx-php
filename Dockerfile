FROM ubuntu:trusty
MAINTAINER mallocworks@gmail.com

ENV DEFAULT_SERVER_HOSTNAME localhost
ENV WWW_ROOT /var/www/default

VOLUME ["$WWW_ROOT"]

EXPOSE 80


# Packages
RUN apt-get update -y --force-yes
RUN apt-get upgrade -y --force-yes

RUN apt-get install -y --force-yes nginx pwgen python-setuptools curl git unzip zip wget vim mysql-client
RUN apt-get install -y --force-yes php5-fpm php5-mysql php5-curl php5-gd php5-intl php-pear php5-imagick php5-imap php5-mcrypt php5-memcache php5-ming php5-ps php5-pspell php5-recode php5-sqlite php5-tidy php5-xmlrpc php5-xsl php5-cli php5-json php-apc 

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# nginx config
RUN sed -i -e"s/keepalive_timeout\s*65/keepalive_timeout 2/" /etc/nginx/nginx.conf
RUN sed -i -e"s/keepalive_timeout 2/keepalive_timeout 2;\n\tclient_max_body_size 100m/" /etc/nginx/nginx.conf
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# php-fpm config
RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/;date.timezone =.*/date.timezone = UTC/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf
RUN sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php5/fpm/pool.d/www.conf
RUN sed -i -e "s/;date.timezone =.*/date.timezone = UTC/g" /etc/php5/cli/php.ini
RUN find /etc/php5/cli/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;

# nginx site conf
ADD ./conf/nginx-default.conf /etc/nginx/sites-available/default
RUN sed -i -e "s/%DEFAULT_SERVER_HOSTNAME%/$DEFAULT_SERVER_HOSTNAME/g" /etc/nginx/sites-available/default
## note: using ',' instead of '/' as $WWW_ROOT contains slashes and will make the sed argument invalid
RUN sed -i -e "s,%WWW_ROOT%,$WWW_ROOT,g" /etc/nginx/sites-available/default

# supervisor config
RUN /usr/bin/easy_install supervisor
RUN /usr/bin/easy_install supervisor-stdout
ADD ./conf/supervisord.conf /etc/supervisord.conf

# Copy default pages
ADD html/* $WWW_ROOT/


CMD ["supervisord", "-n"]