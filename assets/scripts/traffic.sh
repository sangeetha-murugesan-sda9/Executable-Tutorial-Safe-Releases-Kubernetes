#!/usr/bin/env bash
# fake users: ~5 req/s against the counter service, every answer goes into a log
# usage: traffic.sh start|reset|summary|live|stop

LOG=/tmp/traffic.log
PIDFILE=/tmp/traffic.pid
URL=${APP_URL:-http://$(hostname -I | awk '{print $1}'):30080}/

running() { [ -f $PIDFILE ] && kill -0 $(cat $PIDFILE) 2>/dev/null; }

case "$1" in
  loop)
    while true; do
      out=$(curl -s -m 1 -w '|%{http_code}' $URL)
      code=${out##*|}
      ver=$(echo "${out%|*}" | grep -o 'version=[^ ]*' | cut -d= -f2)
      echo "$(date +%s) $(date +%T) $code ${ver:--}" >> $LOG
      sleep 0.2
    done
    ;;
  start)
    running && { echo "already running"; exit 0; }
    > $LOG
    nohup "$(readlink -f "$0")" loop > /dev/null 2>&1 &
    echo $! > $PIDFILE
    echo "sending traffic to $URL (log: $LOG)"
    ;;
  reset)
    > $LOG
    echo "log cleared at $(date +%T)"
    ;;
    summary)
    [ -s $LOG ] || { echo "no requests logged yet, is the generator running?"; exit 0; }
    secs=$(( $(tail -1 $LOG | cut -d' ' -f1) - $(head -1 $LOG | cut -d' ' -f1) ))
    echo "$(wc -l < $LOG) requests in ${secs}s"
    awk '{n[$3" "$4]++} END {for (k in n) {split(k, a, " "); printf "  HTTP %s  %-4s %5d\n", a[1], a[2], n[k]}}' $LOG | sort
    echo "failed (not 200): $(awk '$3 != 200' $LOG | wc -l)"
    ;;
  live)
    tail -n 5 -f $LOG
    ;;
  stop)
    running && kill $(cat $PIDFILE)
    rm -f $PIDFILE
    ;;
  *)
    echo "usage: $0 start|reset|summary|live|stop"
    exit 1
    ;;
esac