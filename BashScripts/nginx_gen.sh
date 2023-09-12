#!/bin/sh

#  wget --no-check-certificate -q -O - 'http://repo.livelinux.info/nginx/nginx_gen.sh' | bash -x -

if [ "$(uname)" == 'Linux' ]; then
    cpu=$((`cat /proc/cpuinfo | grep -c processor`*2))
    dir=\/etc\/nginx
    geoip=\/usr\/share\/GeoIP
    events=epoll
else
    cpu=$((`sysctl hw.ncpu | awk '{print $2}'`*2))
    dir=\/usr\/local\/etc\/nginx
    geoip=\/usr\/local\/share\/GeoIP
    events=kqueue
fi

mkdir -p ~/backup/nginx > /dev/null 2>&1
mkdir -p $dir/conf.d > /dev/null 2>&1
mkdir -p $dir/sites-enabled > /dev/null 2>&1
mkdir -p /etc/nginx/sites-available > /dev/null 2>&1
mkdir -p /etc/nginx/locations.d > /dev/null 2>&1

if [ -f $dir/nginx.conf ]; then
mv $dir/nginx.conf ~/backup/nginx/nginx.conf.`date +%Y-%m-%d_%H-%M`
fi

# get GeoIP 
mkdir $geoip > /dev/null 2>&1
cd $geoip/
wget -q -O GeoIP.dat.gz http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz
gunzip -f -q GeoIP.dat.gz


mkdir -p /var/cache/nginx/{fpm,page,client_temp,ngx_pagespeed,scgi,fastcgi,uwsgi}
chown -R nginx:nginx /var/cache/nginx
chown nginx:nginx "/var/cache/ngx_pagespeed/"
chmod 777 /var/log/nginx/

# **********************************************************************************************
# remove default nginx config 

rm -f $dir/conf.d/default.conf
rm -f $dir/conf.d/virtual.conf
rm -f $dir/conf.d/ssl.conf

# **********************************************************************************************

# ssl tweak
#cd /etc/ssl/certs
#openssl dhparam -out dhparam.pem 2048
#wget -O - https://www.startssl.com/certs/ca.pem | tee -a ca-certs.pem > /dev/null 
#wget -O - https://www.startssl.com/certs/sub.class1.server.ca.pem | tee -a ca-certs.pem > /dev/null 
#wget -O - http://aia.startssl.com/certs/ca.crt | openssl x509 -inform DER -outform PEM | tee -a ca-certs.pem > /dev/null 
#wget -O - http://aia1.wosign.com/ca1g2-server1-free.cer | openssl x509 -inform DER -outform PEM | tee -a ca-certs.pem > /dev/null 
#wget -O - http://aia6.wosign.com/ca6.server1.free.cer | openssl x509 -inform DER -outform PEM | tee -a ca-certs.pem > /dev/null

# create main nginx config

#cat > $dir/pagespeed.conf << EOL
#pagespeed on;
#pagespeed FileCachePath "/var/cache/nginx/ngx_pagespeed/";
#
#pagespeed Statistics on;
#pagespeed StatisticsLogging off;
#pagespeed LogDir /var/log/nginx;
#pagespeed AdminPath /za_pagespeed_admin;
#pagespeed StatisticsLoggingIntervalMs 6000;
#pagespeed StatisticsLoggingMaxFileSizeKb 1024;
#pagespeed EnableCachePurge on;
#
##pagespeed RewriteLevel OptimizeForBandwidth;
#pagespeed RewriteLevel CoreFilters;
#
##pagespeed MemcachedServers "127.0.0.1:11211";
#
#pagespeed EnableFilters insert_dns_prefetch;
#pagespeed EnableFilters remove_quotes;
#pagespeed EnableFilters remove_comments;
#pagespeed EnableFilters collapse_whitespace;
#
#pagespeed EnableFilters remove_quotes;
#pagespeed EnableFilters remove_comments;
#pagespeed EnableFilters collapse_whitespace;
#
#pagespeed JpegRecompressionQuality 85;
#pagespeed ImageRecompressionQuality 85;
#pagespeed ImageInlineMaxBytes 2048;
#pagespeed LowercaseHtmlNames on;
##EOL
#
##cat > $dir/pagespeed2.conf << EOL
#pagespeed on;
#pagespeed FileCachePath "/var/cache/nginx/ngx_pagespeed/";
#pagespeed LogDir /var/log/nginx;
#
#pagespeed Statistics on;
#pagespeed StatisticsLogging off;
#pagespeed LogDir /var/log/nginx;
#pagespeed AdminPath /za_pagespeed_admin;
#pagespeed StatisticsLoggingIntervalMs 6000;
#pagespeed StatisticsLoggingMaxFileSizeKb 1024;
#
##pagespeed RewriteLevel OptimizeForBandwidth;
#pagespeed RewriteLevel CoreFilters;
#
#pagespeed EnableCachePurge on;
##pagespeed MemcachedServers "127.0.0.1:11211";
#
#pagespeed EnableFilters rewrite_images;
#pagespeed EnableFilters resize_images;
#pagespeed EnableFilters insert_image_dimensions;
#
#pagespeed EnableFilters insert_dns_prefetch;
#pagespeed EnableFilters remove_quotes;
#pagespeed EnableFilters remove_comments;
#pagespeed EnableFilters collapse_whitespace;
#
#pagespeed JpegRecompressionQuality 85;
#pagespeed ImageRecompressionQuality 85;
#pagespeed ImageInlineMaxBytes 2048;
#pagespeed LowercaseHtmlNames on;
#
#pagespeed InPlaceResourceOptimization on;
#pagespeed EnableFilters in_place_optimize_for_browser;
#pagespeed PrivateNotVaryForIE off;
##EOL

cat > $dir/cache.conf << EOL
proxy_cache_valid 200 301 302 304 5m;
proxy_cache_key "\$request_method|\$http_if_modified_since|\$http_if_none_match|\$host|\$request_uri";
proxy_ignore_headers "Cache-Control" "Expires";
proxy_cache_use_stale error timeout invalid_header http_500 http_502 http_503 http_504;
proxy_cache_bypass \$cookie_session \$http_x_update;
proxy_cache     pagecache;
EOL

cat > $dir/nginx.conf << EOL   
# worker_processes $cpu;
worker_processes auto;

timer_resolution    100ms;
pid /var/run/nginx.pid;
thread_pool default threads=32 max_queue=655360;

events {
    worker_connections  10000;
    multi_accept  on;
    use $events;
}
http {
    include $dir/mime.types;

    default_type        application/octet-stream;

        log_format      main '\$host $remote_addr - \$remote_user [\$time_local] "\$request"' '\$status \$body_bytes_sent "\$http_referer"' '"\$http_user_agent" "\$http_x_forwarded_for"';
        log_format      defaultServer '[\$time_local][\$server_addr] \$remote_addr (\$http_user_agent) -> "\$http_referer" \$host "\$request" \$status';
        log_format      downloadsLog '[\$time_local] \$remote_addr "\$request"';
        log_format      Counter '[\$time_iso8601] \$remote_addr \$request_uri?\$query_string';

    # log example 
    # access_log unc.log Counter;

    access_log  off;
    access_log  /dev/null main;
    # access_log  /var/log/nginx-main-access.log;
    error_log /dev/null;
  
  #rewrite_log on;
  #error_log /var/log/ispconfig/httpd/st1.xxxx.ru/error.log debug;


    connection_pool_size  256;
    client_header_buffer_size 4k;
    client_max_body_size  2048m;
    large_client_header_buffers 8 32k;
    request_pool_size 4k;
    output_buffers  1 32k;
    postpone_output 1460;

    gzip  on;
    gzip_min_length 1000;
    gzip_proxied  any;
    gzip_types  text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript text/x-javascript application/javascript image/svg+xml svg svgz;
    gzip_disable  "msie6";
    gzip_comp_level 6;
    gzip_http_version 1.0;
    gzip_vary on;
    
    sendfile       on;
    aio            threads;
    directio 10m;

    tcp_nopush  on;
    tcp_nodelay on;
    server_tokens off;
    
    keepalive_timeout 75 20;

    server_names_hash_bucket_size 128;
    server_names_hash_max_size  8192;
    ignore_invalid_headers  on;
    server_name_in_redirect off;
 
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 8.8.4.4 8.8.8.8 valid=300s;
    resolver_timeout 10s;   

    ssl_protocols              TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers 'AES128+EECDH:AES128+EDH';
    ssl_session_cache shared:SSL:50m;
    ssl_prefer_server_ciphers   on;

    #ssl_dhparam /etc/ssl/certs/dhparam.pem;
    #ssl_trusted_certificate /etc/ssl/certs/ca-certs.pem;
    
#    spdy_headers_comp 1;        
#    add_header Alternate-Protocol  443:npn-spdy/3;

#    add_header Strict-Transport-Security "max-age=63072000; includeSubdomains;";
#    add_header X-Content-Type-Options nosniff;
#    add_header X-Frame-Options SAMEORIGIN;
      
    proxy_http_version 1.1;
    proxy_set_header Connection "";
    proxy_buffering off;
    proxy_buffer_size 8k;
    proxy_buffers 8 64k;
    proxy_connect_timeout 300m;
    proxy_read_timeout  300m;
    proxy_send_timeout  300m;
    proxy_store off;
    proxy_ignore_client_abort on;
    
    fastcgi_read_timeout  300m;

    open_file_cache max=200000 inactive=20s;
    open_file_cache_valid 30s;
    open_file_cache_min_uses 2;
    open_file_cache_errors on;

#    charset utf-8;
    
    proxy_cache_path  /var/cache/nginx/page levels=2 keys_zone=pagecache:100m inactive=1h max_size=10g;
    
    fastcgi_cache_path  /var/cache/nginx/fpm levels=2 keys_zone=FPMCACHE:100m inactive=1h max_size=10g;
    fastcgi_cache_key "\$scheme\$request_method\$host$request_uri";
    fastcgi_cache_use_stale error timeout invalid_header http_500;
    fastcgi_ignore_headers Cache-Control Expires Set-Cookie;
    
    fastcgi_buffers 16 16k;
    fastcgi_buffer_size 32k;  

    upstream memcached_backend {  server 127.0.0.1:11211; }
 
    proxy_set_header  Host            \$host;
    proxy_set_header  X-Real-IP       \$remote_addr;
    proxy_set_header  X-Forwarded-For \$proxy_add_x_forwarded_for;

set_real_ip_from 51.255.66.206;
set_real_ip_from 103.21.244.0/22;
set_real_ip_from 103.22.200.0/22;
set_real_ip_from 103.31.4.0/22;
set_real_ip_from 104.16.0.0/12;
set_real_ip_from 108.162.192.0/18;
set_real_ip_from 131.0.72.0/22;
set_real_ip_from 141.101.64.0/18;
set_real_ip_from 162.158.0.0/15;
set_real_ip_from 172.64.0.0/13;
set_real_ip_from 173.245.48.0/20;
set_real_ip_from 188.114.96.0/20;
set_real_ip_from 190.93.240.0/20;
set_real_ip_from 197.234.240.0/22;
set_real_ip_from 198.41.128.0/17;
set_real_ip_from 199.27.128.0/21;
set_real_ip_from 2400:cb00::/32;
set_real_ip_from 2606:4700::/32;
set_real_ip_from 2803:f800::/32;
set_real_ip_from 2405:b500::/32;
set_real_ip_from 2405:8100::/32;
set_real_ip_from 2c0f:f248::/32;
set_real_ip_from 2a06:98c0::/29;

real_ip_header  X-Real-IP;
#real_ip_header CF-Connecting-IP;
#real_ip_header X-Forwarded-For;


    allow all;

#    geoip_country $geoip/GeoIP.dat;
#    map \$geoip_country_code \$allowed_country {
#    default no;
#    RU yes;
#    KZ yes;
#    BY yes;
#    UA yes;
#    }

# block country 
#    if (\$allowed_country = no) {
#    return 444;
#    }

server {
        listen   80 reuseport;
}



#upstream web {
#server         1.1.1.1 weight=10 max_fails=60 fail_timeout=2s;
#keepalive 10;
#
#}
#server  {
#   listen   80;
#    location / {
#        proxy_pass      http://web;
#proxy_set_header   Host   \$host;
#proxy_set_header   X-Real-IP  \$remote_addr;
#proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
#}
#}
      include $dir/conf.d/*.conf;
#    include /etc/nginx/sites-enabled/*.vhost;
}
EOL