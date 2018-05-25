FROM daocloud.io/php:7.2-fpm

# 切换 apt 镜像源(本地测试打开,daocloud 线上可以注释)
# COPY sources.list /etc/apt/sources.list

# 安装依赖
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y \
        wget \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        git \
        supervisor \
        nginx \
        cron \
        redis-server \
        --no-install-recommends \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/ \
    && docker-php-ext-install \
        gd \
        mysqli \
        pdo_mysql \
        mbstring \
        opcache \
        zip \
        bcmath \
    && pecl install mcrypt-1.0.1 \
    && docker-php-ext-enable mcrypt \
    && apt-get clean \
    && apt-get autoclean \
    && rm -rf /usr/src/php* \ 
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 安装composer
ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_HOME /tmp
ENV COMPOSER_VERSION 1.6.5

RUN curl -s -f -L -o /tmp/installer.php https://raw.githubusercontent.com/composer/getcomposer.org/b107d959a5924af895807021fcef4ffec5a76aa9/web/installer \
 && php -r " \
    \$signature = '544e09ee996cdf60ece3804abc52599c22b1f40f4323403c44d44fdfdd586475ca9813a858088ffbc1f233e9b180f061'; \
    \$hash = hash('SHA384', file_get_contents('/tmp/installer.php')); \
    if (!hash_equals(\$signature, \$hash)) { \
        unlink('/tmp/installer.php'); \
        echo 'Integrity check failed, installer is either corrupt or worse.' . PHP_EOL; \
        exit(1); \
    }" \
 && php /tmp/installer.php --no-ansi --install-dir=/usr/bin --filename=composer --version=${COMPOSER_VERSION} \
 && composer --ansi --version --no-interaction \
 && rm -rf /tmp/* /tmp/.htaccess

# 设置时区
RUN /bin/cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
  && echo 'Asia/Shanghai' >/etc/timezone

# 系统配置文件替换
COPY image-files/ /
RUN rm -rf /etc/nginx/sites-enabled/default /etc/nginx/sites-aviable/default

# 操作权限
RUN chmod 700 \
    /usr/local/bin/docker-entrypoint.sh \
    /usr/local/bin/docker-run.sh

# 项目目录
RUN mkdir /app && chown www-data:www-data /app
WORKDIR /app

# 额外的环境变量
ENV YII_MIGRATION_DO=0 \
    # 多个路径写法：/app/web/assets\ /app/runtime
    VOLUME_PATH=''

EXPOSE 80

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["docker-run.sh"]
