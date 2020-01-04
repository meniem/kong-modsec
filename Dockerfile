FROM ubuntu:bionic

ENV KONG_VERSION 1.3.0

# Install Kong version 1.3.0 on Ubuntu 18.04
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl perl unzip openssl \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSLo kong.deb https://bintray.com/kong/kong-deb/download_file?file_path=kong-${KONG_VERSION}.bionic.all.deb \
    && apt-get purge -y --auto-remove ca-certificates curl \
	&& dpkg -i kong.deb \
	&& rm -rf kong.deb

# Install all required perequisite pckages for ModSecurity
RUN apt-get update \
    && apt-get install -y apt-utils autoconf automake build-essential git libcurl4-openssl-dev libgeoip-dev liblmdb-dev libpcre++-dev libtool libxml2-dev libyajl-dev pkgconf wget zlib1g-dev libssl-dev
	
# Download and Compile the ModSecurity 3.0 Source Code
RUN cd /tmp \
    && git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity \
    && cd ModSecurity \
    && git submodule init \
    && git submodule update \
    && ./build.sh \
    && ./configure \
    && make \
    && make install

# Download the NGINX Connector for ModSecurity and Compile it as a Dynamic Module
RUN cd /tmp \
    && git clone https://github.com/SpiderLabs/ModSecurity-nginx \
    && wget https://openresty.org/download/openresty-1.13.6.2.tar.gz \
    && tar -xvzf openresty-1.13.6.2.tar.gz \
    && cd openresty-1.13.6.2 \
    && ./configure --add-module=/tmp/ModSecurity-nginx --with-pcre-jit --with-http_ssl_module --with-http_realip_module --with-http_stub_status_module --with-http_v2_module \
    && make -j2 \
    && make install \
	&& export PATH=/usr/local/openresty/bin:$PATH

# Configure ModSecurity
RUN mkdir -p /usr/local/openresty/nginx/modsec \
    && cd /usr/local/openresty/nginx/modsec \
    && wget https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/modsecurity.conf-recommended \
    && mv modsecurity.conf-recommended modsecurity.conf \
    && sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' modsecurity.conf \
    && cp /tmp/ModSecurity/unicode.mapping .

COPY main.conf /usr/local/openresty/nginx/modsec/main.conf

# Delete all temp and unnecessary files
RUN rm -Rf /tmp/openresty-1.13.6.2.tar.gz \
    && rm -Rf /tmp/ModSecurity \
    && rm -Rf ~/.cache

# Configure and Enable ModSecurity on OpenResty-Nginx
RUN sed -i 's/server_name\ \ localhost;/server_name\ \ localhost;\n\ \ \ \ modsecurity\ on;\n\ \ \ \ modsecurity_rules_file\ \/usr\/local\/openresty\/nginx\/modsec\/main.conf;/' /usr/local/openresty/nginx/conf/nginx.conf

# Configure and Enable ModSecurity on Kong-Nginx
RUN sed -i 's/server_name\ kong;/server_name\ kong;\n\ \ \ \ modsecurity\ on;\n\ \ \ \ modsecurity_rules_file\ \/usr\/local\/openresty\/nginx\/modsec\/main.conf;/' /usr/local/share/lua/5.1/kong/templates/nginx_kong.lua

RUN sed -i 's/server_name\ kong_admin;/server_name\ kong_admin;\n\ \ \ \ modsecurity\ on;\n\ \ \ \ modsecurity_rules_file\ \/usr\/local\/openresty\/nginx\/modsec\/main.conf;/'     

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod a+x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 8000 8443 8001 8444

STOPSIGNAL SIGQUIT

CMD ["kong", "docker-start"]
