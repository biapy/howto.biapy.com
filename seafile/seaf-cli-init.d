#!/bin/bash
### BEGIN INIT INFO
# Provides:          seaf-cli-%USER%
# Required-Start:    $remote_fs $syslog $network
# Required-Stop:     $remote_fs $syslog $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Seafile client for user %USER%
# Description:       Seafile client init.d script.
### END INIT INFO

# Author: Pierre-Yves Landuré <pierre-yves.landure@biapy.fr>

# Do NOT "set -e"

# PATH should only include /usr/* if it runs after the mountnfs.sh script
PATH='/sbin:/usr/sbin:/bin:/usr/bin:/usr/local/bin'
DESC='Seafile client for user %USER%'
NAME='seaf-cli-%USER%'
DAEMON='/usr/local/bin/seaf-cli'
SCRIPTNAME="/etc/init.d/${NAME}"

USER='%USER%'
GROUP='%USER%'

# Exit if the package is not installed
[ -x "${DAEMON}" ] || exit 0

# Read configuration variable file if it is present
[ -r "/etc/default/${NAME}" ] && . "/etc/default/${NAME}"

# Load the VERBOSE setting and other rcS variables
. '/lib/init/vars.sh'

# Define LSB log_* functions.
# Depend on lsb-base (>= 3.2-14) to ensure that this file is present
# and status_of_proc is working.
. '/lib/lsb/init-functions'

#
# Function that starts the daemon/service
#
do_start()
{
  command sudo -u "${USER}" -- "${DAEMON}" 'start'

  return 0
}

#
# Function that stops the daemon/service
#
do_stop()
{
  command sudo -u "${USER}" -- "${DAEMON}" 'stop'

  return 0
}

#
# Function that sends a SIGHUP to the daemon/service
#
do_reload() {
	#
	# If the daemon can reload its configuration without
	# restarting (for example, when it is sent a SIGHUP),
	# then implement that here.
	#
	start-stop-daemon --stop --signal 1 --quiet --pidfile "${PIDFILE}" --name "${NAME}"
	return 0
}

case "${1}" in
  start)
	[ "${VERBOSE}" != no ] && log_daemon_msg "Starting ${DESC}" "${NAME}"
	do_start
	case "${?}" in
		0|1) [ "${VERBOSE}" != no ] && log_end_msg 0 ;;
		2) [ "${VERBOSE}" != no ] && log_end_msg 1 ;;
	esac
	;;
  stop)
	[ "${VERBOSE}" != no ] && log_daemon_msg "Stopping ${DESC}" "${NAME}"
	do_stop
	case "${?}" in
		0|1) [ "${VERBOSE}" != no ] && log_end_msg 0 ;;
		2) [ "${VERBOSE}" != no ] && log_end_msg 1 ;;
	esac
	;;
  restart|force-reload)
	#
	# If the "reload" option is implemented then remove the
	# 'force-reload' alias
	#
	log_daemon_msg "Restarting ${DESC}" "${NAME}"
	do_stop
	case "${?}" in
	  0|1)
		do_start
		case "${?}" in
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
		command sudo -u "${USER}" -- "${DAEMON}" "${@}"
	;;

  *)
	echo "Usage: $SCRIPTNAME {start|stop|status|restart|force-reload|init|list|download|sync|desync|create|config|--status-all}" >&2
	exit 3
	;;
esac

:
