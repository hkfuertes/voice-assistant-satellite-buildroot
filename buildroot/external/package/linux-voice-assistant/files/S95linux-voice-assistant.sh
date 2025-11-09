#!/bin/sh
#
# linux-voice-assistant daemon
#

NAME="linux-voice-assistant"
DAEMON="/usr/bin/python3"
DAEMON_ARGS="-m linux_voice_assistant --name $(hostname) --audio-output-device alsa/sysdefault"
PIDFILE="/var/run/$NAME.pid"

start() {
    echo -n "Starting $NAME: "
    
    # Ensure audio devices are ready
    sleep 1
    
    start-stop-daemon -S -q -b -m -p "$PIDFILE" \
        --exec $DAEMON -- $DAEMON_ARGS
    
    [ $? = 0 ] && echo "OK" || echo "FAIL"
}

stop() {
    echo -n "Stopping $NAME: "
    start-stop-daemon -K -q -p "$PIDFILE"
    [ $? = 0 ] && echo "OK" || echo "FAIL"
    rm -f "$PIDFILE"
}

restart() {
    stop
    sleep 2
    start
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart|reload)
        restart
        ;;
    *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
esac

exit $?
