#!/bin/bash

### BEGIN INIT INFO
# Provides:          seafile-%DOMAIN%
# Required-Start:    $local_fs $remote_fs $network
# Required-Stop:     $local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Seafile Server for %DOMAIN%
# Description:       Seafile Server for %DOMAIN%
### END INIT INFO


INSTALLPATH="%INSTALL_PATH%/current"

DESC="Seafile for %DOMAIN%"
NAME='seafile-%DOMAIN%'
PIDFILE="/var/run/${NAME}.pid"
SCRIPTNAME="/etc/init.d/${NAME}"

USER='seafile'
GROUP='seafile'


# Exit if the package is not installed
[ -e "${INSTALLPATH}" ] || exit 0

# Read configuration variable file if it is present
[ -r /etc/default/$NAME ] && . /etc/default/$NAME

# Load the VERBOSE setting and other rcS variables
. /lib/init/vars.sh

# Define LSB log_* functions.
# Depend on lsb-base (>= 3.2-14) to ensure that this file is present
# and status_of_proc is working.
. /lib/lsb/init-functions

TOPDIR=$(dirname "${INSTALLPATH}")
default_ccnet_conf_dir=${TOPDIR}/ccnet
ccnet_pidfile=${INSTALLPATH}/runtime/ccnet.pid
seaf_controller="${INSTALLPATH}/seafile/bin/seafile-controller"


export PATH=${INSTALLPATH}/seafile/bin:$PATH
export SEAFILE_LD_LIBRARY_PATH=${INSTALLPATH}/seafile/lib/:${INSTALLPATH}/seafile/lib64:${LD_LIBRARY_PATH}

script_name=$0
function usage () {
    echo "Usage: "
    echo "  ${SCRIPTNAME} { start | stop | restart }"
    echo ""
}

# check args
if [[ $# != 1 || ( "$1" != "start" && "$1" != "stop" && "$1" != "restart" ) ]]; then
    usage;
    exit 1;
fi

function validate_ccnet_conf_dir () {
    if [[ ! -d ${default_ccnet_conf_dir} ]]; then
        echo "Error: there is no ccnet config directory."
        echo "Have you run setup-seafile.sh before this?"
        echo ""
        exit -1;
    fi
}

function read_seafile_data_dir () {
    seafile_ini=${default_ccnet_conf_dir}/seafile.ini
    if [[ ! -f ${seafile_ini} ]]; then
        echo "${seafile_ini} not found. Now quit"
        exit 1
    fi
    seafile_data_dir=$(cat "${seafile_ini}")
    if [[ ! -d ${seafile_data_dir} ]]; then
        echo "Your seafile server data directory \"${seafile_data_dir}\" is invalid or doesn't exits."
        echo "Please check it first, or create this directory yourself."
        echo ""
        exit 1;
    fi
}

function test_config() {
    if ! LD_LIBRARY_PATH=$SEAFILE_LD_LIBRARY_PATH ${seaf_controller} --test -c "${default_ccnet_conf_dir}" -d "${seafile_data_dir}"; then
        exit 1;
    fi
}

function check_component_running() {
    name=$1
    cmd=$2
    if pid=$(pgrep -f "$cmd" 2>/dev/null); then
        echo "[$name] is running, pid $pid. You can stop is by: "
        echo
        echo "        kill $pid"
        echo
        echo "Stop it and try again."
        echo
        exit
    fi
}

function validate_already_running () {
    if pid=$(pgrep -f "seafile-controller -c ${default_ccnet_conf_dir}" 2>/dev/null); then
        echo "Seafile controller is already running, pid $pid"
        echo
        exit 1;
    fi

    check_component_running "ccnet-server" "ccnet-server -c"
    check_component_running "seaf-server" "seaf-server -c"
    check_component_running "seaf-mon" "seaf-mon -c"
    check_component_running "httpserver" "httpserver -c"
}

function do_start () {
    validate_already_running;
    validate_ccnet_conf_dir;
    read_seafile_data_dir;
    test_config;

    echo "Starting seafile server, please wait ..."

    ## LD_LIBRARY_PATH=$SEAFILE_LD_LIBRARY_PATH ${seaf_controller} -c "${default_ccnet_conf_dir}" -d "${seafile_data_dir}"
    LD_LIBRARY_PATH=$SEAFILE_LD_LIBRARY_PATH start-stop-daemon --start --quiet \
        --pidfile $PIDFILE --user "${USER}" --group "${GROUP}" --exec ${seaf_controller} -- \
         -c "${default_ccnet_conf_dir}" -d "${seafile_data_dir}" \
        || return 2

    sleep 3

    # check if seafile server started successfully
    if ! pgrep -f "seafile-controller -c ${default_ccnet_conf_dir}" 2>/dev/null 1>&2; then
        # echo "Failed to start seafile server"
        return 2;
    fi

    # echo "Seafile server started"
    # echo
}

function do_stop () {
    if ! pgrep -f "seafile-controller -c ${default_ccnet_conf_dir}" 2>/dev/null 1>&2; then
        # echo "seafile server not running yet"
        return 1;
    fi

    echo "Stopping seafile server ..."
    pkill -SIGTERM -f "seafile-controller -c ${default_ccnet_conf_dir}"
    pkill ccnet-server
    pkill seaf-server
    pkill seaf-mon
    pkill httpserver
    return 0
}

case $1 in
    "start" )
        [ "$VERBOSE" != no ] && log_daemon_msg "Starting $DESC" "$NAME"
        do_start
        case "$?" in
            0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
            2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
        esac
        ;;
    "stop" )
        [ "$VERBOSE" != no ] && log_daemon_msg "Stopping $DESC" "$NAME"
        do_stop
        case "$?" in
            0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
            2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
        esac
        ;;
    'restart' | 'force-reload' )
        #
        # If the "reload" option is implemented then remove the
        # 'force-reload' alias
        #
        log_daemon_msg "Restarting $DESC" "$NAME"
        do_stop
        sleep 2
        case "$?" in
          0|1)
            do_start
            case "$?" in
                0) log_end_msg 0 ;;
                1) log_end_msg 1 ;; # Old process is still running
                *) log_end_msg 1 ;; # Failed to start
            esac
            ;;
          *)
            # Failed to stop
            log_end_msg 1
            ;;
        esac
        ;;
    *)
        #echo "Usage: $SCRIPTNAME {start|stop|restart|reload|force-reload}" >&2
        echo "Usage: $SCRIPTNAME {start|stop|restart|force-reload}" >&2
        exit 3
        ;;
esac

: