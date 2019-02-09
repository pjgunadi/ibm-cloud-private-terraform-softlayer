# Example configuration for a possible web application.  See the
# full configuration options online.
#
#   http://haproxy.1wt.eu/download/1.4/doc/configuration.txt
#
# Global settings     
global
      # To view messages in the /var/log/haproxy.log you need to:
      #
      # 1) Configure syslog to accept network log events.  This is done
      #    by adding the '-r' option to the SYSLOGD_OPTIONS in
      #    /etc/sysconfig/syslog.
      #
      # 2) Configure local2 events to go to the /var/log/haproxy.log
      #   file. A line similar to the following can be added to
      #   /etc/sysconfig/syslog.
      #
      #    local2.*                       /var/log/haproxy.log
      #
      log         127.0.0.1 local2

      pidfile     /var/run/haproxy.pid
      maxconn     4000
      daemon

# Common defaults that all the 'listen' and 'backend' sections
# use, if not designated in their block.     
  defaults
      mode                    http
      log                     global
      option                  httplog
      option                  dontlognull
      option http-server-close
      option                  redispatch
      retries                 3
      timeout http-request    10s
      timeout queue           1m
      timeout connect         10s
      timeout client          1m
      timeout server          1m
      timeout http-keep-alive 10s
      timeout check           10s
      maxconn                 3000

  frontend k8s-api 
      bind :8001
      mode tcp
      option tcplog
      use_backend k8s-api

  backend k8s-api
      mode tcp
      balance roundrobin
${k8s_api} 

  frontend dashboard 
      bind :8443
      mode tcp
      option tcplog
      use_backend dashboard

  backend dashboard
      mode tcp
      balance roundrobin
${dashboard}

  frontend auth 
      bind :9443
      mode tcp
      option tcplog
      use_backend auth

  backend auth
      mode tcp
      balance roundrobin
${auth} 

  frontend registry 
      bind :8500
      mode tcp
      option tcplog
      use_backend registry

  frontend image-manager 
      bind :8600
      mode tcp
      option tcplog
      use_backend image-manager

  backend image-manager
      mode tcp
      balance roundrobin
${image_manager} 

  backend registry
      mode tcp
      balance roundrobin
${registry} 

  frontend cam
      bind :30000
      mode tcp
      option tcplog
      use_backend cam

  backend cam
      mode tcp
      balance roundrobin
${cam}

  frontend proxy-http 
      bind :80
      mode tcp
      option tcplog
      use_backend proxy-http

  backend proxy-http
      mode tcp
      balance roundrobin
${proxy_http} 

  frontend proxy-https 
      bind :443
      mode tcp
      option tcplog
      use_backend proxy-https

  backend proxy-https
      mode tcp
      balance roundrobin
${proxy_https} 
