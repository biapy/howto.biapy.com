#!/bin/bash

### BEGIN INIT INFO
# Provides:          seahub-%DOMAIN%
# Required-Start:    $local_fs $remote_fs $network
# Required-Stop:     $local_fs
# Default-Start:     1 2 3 4 5
# Default-Stop:
# Short-Description: Seahub for %DOMAIN%
# Description:       Seahub for %DOMAIN%
### END INIT INFO

INSTALLPATH="%INSTALL_PATH%/current"

DESC="Seahub for %DOMAIN%"
NAME='seahub-%DOMAIN%'
PIDFILE="/var/run/${NAME}.pid"
SCRIPTNAME="/etc/init.d/${NAME}"

MODE='fastcgi'
PORT=8000

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

manage_py=${INSTALLPATH}/seahub/manage.py
gunicorn_conf=${INSTALLPATH}/runtime/seahub.conf
pidfile=${INSTALLPATH}/runtime/seahub.pid
errorlog=${INSTALLPATH}/runtime/error.log
accesslog=${INSTALLPATH}/runtime/access.log


script_name=$0
function usage () {
    echo "Usage: "
    echo "  ${SCRIPTNAME} { start | stop | restart }"
    echo ""
}

# Check args
if [[ $1 != "start" && $1 != "stop" && $1 != "restart" \
    && $1 != "start-fastcgi" && $1 != "restart-fastcgi" ]]; then
    usage;
    exit 1;
fi

function check_python_executable() {
    if [[ "$PYTHON" != "" && -x $PYTHON ]]; then
        return 0
    fi

    if which python2.7 2>/dev/null 1>&2; then
        PYTHON=python2.7
    elif which python27 2>/dev/null 1>&2; then
        PYTHON=python27
    elif which python2.6 2>/dev/null 1>&2; then
        PYTHON=python2.6
    elif which python26 2>/dev/null 1>&2; then
        PYTHON=python26
    else
        echo
        echo "Can't find a python executable of version 2.6 or above in PATH"
        echo "Install python 2.6+ before continue."
        echo "Or if you installed it in a non-standard PATH, set the PYTHON enviroment varirable to it"
        echo
        exit 1
    fi
}

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

function validate_seahub_running () {
    if pgrep -f "${manage_py}" 2>/dev/null 1>&2; then
        echo "Seahub is already running."
        exit 1;
    fi
}

function validate_port () {
    if ! [[ ${PORT} =~ ^[1-9][0-9]{1,4}$ ]] ; then
        printf "\033[033m${PORT}\033[m is not a valid port number\n\n"
        usage;
        exit 1
    fi
}

if [[ ($1 == "start" || $1 == "restart") \
    && ($# == 1) ]]; then
elif [[ $1 == "stop" && $# == 1 ]]; then
    dummy=dummy
else
    usage;
    exit 1
fi

function before_start() {
    check_python_executable;
    validate_ccnet_conf_dir;
    read_seafile_data_dir;

    validate_seahub_running;

    export CCNET_CONF_DIR=${default_ccnet_conf_dir}
    export SEAFILE_CONF_DIR=${seafile_data_dir}
    export PYTHONPATH=${INSTALLPATH}/seafile/lib/python2.6/site-packages:${INSTALLPATH}/seafile/lib64/python2.6/site-packages:${INSTALLPATH}/seahub/thirdpart:$PYTHONPATH
    export PYTHONPATH=${INSTALLPATH}/seafile/lib/python2.7/site-packages:${INSTALLPATH}/seafile/lib64/python2.7/site-packages:$PYTHONPATH
}

function do_start () {
    before_start;
    # echo "Starting seahub at port ${PORT} ..."

    if pgrep -f "${manage_py}" 1>/dev/null; then
        # printf "\033[33mError:Seahub already started.\033[m\n"
        return 1;
    fi

    if [ "${MODE}" != 'fastcgi' ]; then
        ## $PYTHON "${manage_py}" run_gunicorn -c "${gunicorn_conf}" -b "0.0.0.0:${PORT}"

        start-stop-daemon --start --quiet --pidfile $PIDFILE \
            --user "${USER}" --group "${GROUP}" --exec $PYTHON -- \
            "${manage_py}" run_gunicorn -c "${gunicorn_conf}" -b "0.0.0.0:${PORT}" \
            || return 2
    else
        ## $PYTHON "${manage_py}" runfcgi host=127.0.0.1 port=${PORT} pidfile=$pidfile \
        ##    outlog=${accesslog} errlog=${errorlog}

        start-stop-daemon --start --quiet --pidfile $PIDFILE \
            --user "${USER}" --group "${GROUP}" --exec $PYTHON -- \
            "${manage_py}" runfcgi host=127.0.0.1 port=${PORT} pidfile=$pidfile \
            outlog=${accesslog} errlog=${errorlog} \
            || return 2
    fi

    # Ensure seahub is started successfully
    sleep 5
    if ! pgrep -f "${manage_py}" 2>/dev/null 1>&2; then
        # printf "\033[33mError:Seahub failed to start.\033[m\n"
        # echo "Please try to run \"./seafile.sh start\" again"
        return 2;
    fi
}

function do_stop () {
    before_start;

    # Return
    #   0 if daemon has been stopped
    #   1 if daemon was already stopped
    #   2 if daemon could not be stopped
    #   other if a failure occurred
    start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile $PIDFILE
    RETVAL="$?"
    [ "$RETVAL" = 2 ] && return 2

    # Many daemons don't delete their pidfiles when they exit.
    rm -f $PIDFILE
    return "$RETVAL"
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
esac

echo "Done."
echo ""