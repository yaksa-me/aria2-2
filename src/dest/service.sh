#!/usr/bin/env sh
#
# Aria2 service

# import DroboApps framework functions
. /etc/service.subr

framework_version="2.1"
name="aria2"
version="1.17.1"
description="HTTP/FTP download manager"
depends=""
webui=":6880/"

prog_dir="$(dirname "$(realpath "${0}")")"
daemon="${prog_dir}/bin/aria2c"
conffile="${prog_dir}/etc/aria2.conf"
sessionfile="${prog_dir}/var/aria2.session"
tmp_dir="/tmp/DroboApps/${name}"
pidfile="${tmp_dir}/pid.txt"
logfile="${tmp_dir}/log.txt"
statusfile="${tmp_dir}/status.txt"
errorfile="${tmp_dir}/error.txt"

webserver="${prog_dir}/libexec/web_server"
confweb="${prog_dir}/etc/web_server.conf"
pidweb="/tmp/DroboApps/${name}/web_server.pid"

# backwards compatibility
if [ -z "${FRAMEWORK_VERSION:-}" ]; then
  . "${prog_dir}/libexec/service.subr"
fi

# _is_pid_running
# $1: daemon
# $2: pidfile
# returns: 0 if pid is running, 1 if not running or if pidfile does not exist.
_is_pid_running() {
  /sbin/start-stop-daemon -K -t -x "${1}" -p "${2}" -q
}

# _is_running
# returns: 0 if app is running, 1 if not running or pidfile does not exist.
_is_running() {
#  if ! _is_pid_running "${webserver}" "${pidweb}"; then return 1; fi
  if ! _is_pid_running "${daemon}" "${pidfile}"; then return 1; fi
  return 0;
}

# _is_stopped
# returns: 0 if app is stopped, 1 if running.
_is_stopped() {
#  if _is_pid_running "${webserver}" "${pidweb}"; then return 1; fi
  if _is_pid_running "${daemon}" "${pidfile}"; then return 1; fi
  return 0;
}

_create_session() {
  local sessiondir="$(dirname ${sessionfile})"
  if [ ! -d "${sessiondir}" ]; then mkdir -p "${sessiondir}"; fi
  if [ ! -f "${sessionfile}" ]; then touch "${sessionfile}"; fi
}

start() {
  _create_session
  export HOME="${prog_dir}/var"
  "${daemon}" --conf-path="${conffile}" --daemon=true
  echo $(pidof $(basename "${daemon}")) > "${pidfile}"
  if ! _is_pid_running "${webserver}" "${pidweb}"; then
    "${webserver}" "${confweb}" & echo $! > "${pidweb}"
  fi
}

stop() {
  /sbin/start-stop-daemon -K -x "${webserver}" -p "${pidweb}" -v
  /sbin/start-stop-daemon -K -x "${daemon}" -p "${pidfile}" -v
}

force_stop() {
  /sbin/start-stop-daemon -K -s 9 -x "${webserver}" -p "${pidweb}" -v
  /sbin/start-stop-daemon -K -s 9 -x "${daemon}" -p "${pidfile}" -v
}

# boilerplate
if ! grep -q ^tmpfs /proc/mounts; then mount -t tmpfs tmpfs /tmp; fi
if [ ! -d "${tmp_dir}" ]; then mkdir -p "${tmp_dir}"; fi
exec 3>&1 4>&2 1>> "${logfile}" 2>&1
STDOUT=">&3"
STDERR=">&4"
echo "$(date +"%Y-%m-%d %H-%M-%S"):" "${0}" "${@}"
set -o errexit  # exit on uncaught error code
set -o nounset  # exit on unset variable
set -o xtrace   # enable script tracing

main "${@}"
