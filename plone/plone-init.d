#!/bin/bash

### BEGIN INIT INFO
# Provides:          plone-%INSTANCE_NAME%
# Required-Start:    $syslog $local_fs
# Required-Stop:     $syslog $syslog
# Should-Start:      $local_fs
# Should-Stop:       $local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start Plone %INSTANCE_NAME% instances
# Description:       Start the instances defined in /etc/default/plone-%INSTANCE_NAME%
### END INIT INFO

INSTANCE_NAME="%INSTANCE_NAME%"
INSTANCE_FOLDER="%INSTALL_PATH%"


[ -d ${INSTANCE_FOLDER} -a -d /usr/local/Plone ] || exit 0

. /lib/lsb/init-functions
. /etc/default/plone-${INSTANCE_NAME}

if [ "$ZEOSERVERS" = "NONE" -o "$ZEOSERVERS" = "" ]; then
    ZEOSERVERS=''
    log_warning_msg "Plone - ${INSTANCE_NAME} : ZEO servers have been disabled, edit /etc/default/plone-${INSTANCE_NAME} to enable them."
elif [ "$ZEOSERVERS" = "ALL" ]; then
    ZEOSERVERS=$(command grep --files-with-matches --recursive "zeoserver.ctl" ${INSTANCE_FOLDER}/bin)
fi

if [ "$INSTANCES" = "NONE" -o "$INSTANCES" = "" ]; then
    INSTANCES=''
    log_warning_msg "Plone - ${INSTANCE_NAME}: instances have been disabled, edit /etc/default/plone-${INSTANCE_NAME} to enable them."
elif [ "$INSTANCES" = "ALL" ]; then
    INSTANCES=$(command grep --files-with-matches --recursive "zope2instance.ctl.main" ${INSTANCE_FOLDER}/bin)
fi

case "$1" in
    start|stop|restart|logreopen)
        p=''; [ "$1" = "stop" ] && p='p'

        if [ -n "$ZEOSERVERS" ]; then
          for i in $ZEOSERVERS ; do

                    if [ "$i" = "*" ]; then
                        log_success_msg "Plone - ${INSTANCE_NAME}: no ZEO servers found."
                        break
                    fi

                    if [ -x ${i} ] ; then
                        SCRIPT_NAME=$(/usr/bin/basename ${i})
                        log_begin_msg "Plone - ${INSTANCE_NAME}: ${1}${p}ing ${SCRIPT_NAME} ZEO server"
                        ${i} $1 >/dev/null 2>&1
                        log_end_msg $?
                    else
                        if [ -x ${INSTANCE_FOLDER}/bin/${i} ] ; then
                            log_begin_msg "Plone - ${INSTANCE_NAME}: ${1}${p}ing $i ZEO server"
                            ${INSTANCE_FOLDER}/bin/${i} $1 >/dev/null 2>&1
                            log_end_msg $?
                        else 
                            log_warning_msg "Plone - ${INSTANCE_NAME}: skipping $i (old/purged)"
                        fi
                    fi
            done
        fi

        if [ -n "$INSTANCES" ]; then
            for i in $INSTANCES ; do
                    if [ "$i" = "*" ]; then
                        log_success_msg "Plone - ${INSTANCE_NAME}: no instances found."
                        break
                    fi

                    if [ -x ${i} ] ; then
                        SCRIPT_NAME=$(/usr/bin/basename ${i})
                        log_begin_msg "Plone - ${INSTANCE_NAME}: ${1}${p}ing ${SCRIPT_NAME} instance"
                        ${i} $1 >/dev/null 2>&1
                        log_end_msg $?
                    else
                        if [ -x ${INSTANCE_FOLDER}/bin/${i} ] ; then
                            log_begin_msg "Plone - ${INSTANCE_NAME}: ${1}${p}ing $i instance"
                            ${INSTANCE_FOLDER}/bin/${i} $1 >/dev/null 2>&1
                            log_end_msg $?
                        else 
                            log_warning_msg "Plone - ${INSTANCE_NAME}: skipping $i (old/purged)"
                        fi
                    fi
            done
        fi
        ;;

    force-reload)
        echo "Plone - ${INSTANCE_NAME} doesn't support force-reload, use restart instead."
        ;;

    *)
        echo "Usage: /etc/init.d/plone-${INSTANCE_NAME} {start|stop|restart|logreopen|force-reload}"
        exit 1
        ;;
esac

exit 0
