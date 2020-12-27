#!/bin/sh

set -e

# logging functions
shell_log() {
	local type="$1"; shift
	printf '%s [%s] [Entrypoint]: %s\n' "$(date -I'seconds')" "$type" "$*"
}
shell_note() {
	shell_log Info "$@"
}
shell_warn() {
	shell_log Warn "$@" >&2
}
shell_error() {
	shell_log Error "$@" >&2
	exit 1
}

if [ "$1" = "supervisord" -o "$1" = "/usr/bin/supervisord" ]; then
    # generate Corefile template when firt run
    if [ ! -f Corefile ];then
        cat <<EOF >Corefile
.:53 {
  hosts {
    127.0.0.1 ns1.mydns.local
    127.0.0.2 ns2.mydns.local
    ttl 60
    reload 1m
    fallthrough
  }

  # lkvs is the core for service of domain admin,can not remove!
  lkvs
  
  forward . /etc/resolv.conf
  cache 120
  reload 6s
  errors
}
EOF
        BASE_ADDR_FOR_MASTER=""
        # can not defined master and slave in one container
        if [ ! -z "${SLAVE:-}" -a ! -z "${MASTER:-}" ];then
            shell_error "can not defined environment variable MASTER and SLAVE in one container,one of them is enough"
        else
            if [ ! -z "${SLAVE:-}" ];then
                #sed -i "/#defined slave under master mode only/a\    slave ${SLAVE:-}" Corefile
                shell_note "mydns running under master mode"
                shell_note "you should publish 2 ports of this container"
                shell_note "port 80/tcp for web admin"
                shell_note "port 53/udp for dns request"
                shell_note "${SLAVE:-}(slave) would be allow to get sync"
            fi
            if [ ! -z "${MASTER:-}" ];then
                #sed -i "/#defined master under slave mode only/a\    master ${MASTER:-}:5500" Corefile
                BASE_ADDR_FOR_MASTER=${MASTER:-}
                shell_note "mydns running under slave mode"
                shell_note "you should publish 1 port of this container"
                shell_note "port 53/udp for dns request"
                shell_note "would get sync from ${MASTER:-}(master),make sure master is running"
            fi
        fi

        # default mode is master if [MASTER,SLAVE] are miss either
        if [ -z "${SLAVE:-}" -a -z "${MASTER:-}" ];then
            shell_note "run under master mode because of environment variable MASTER and SLAVE are miss either"
        fi

        # replace __MASTER__ by BASE_ADDR_FOR_MASTER
        sed -i "s/__MASTER__/${BASE_ADDR_FOR_MASTER:-}/" /var/www/html/index.html

        # turn on debug if DEBUG_ON is set
        if [ ! -z ${DEBUG_ON:-} ];then
            sed -i "/errors/i\  log" Corefile
        fi
    fi
fi

exec "$@"