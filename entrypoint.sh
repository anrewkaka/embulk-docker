#!/bin/sh
if [ -n "$PLUGINS" ] ; then
  embulk gem install $PLUGINS
fi
if [ -f "$BUNDLE_FILE" ] ; then
  BUNDLE="-b $BUNDLE_FILE"
fi
CONFIG="${CONFIG:-/etc/embulk/config.yml}"
RESUME="-r ${RESUME:-/etc/embulk/resume.txt}"
LOG_LEVEL="-l ${LOG_LEVEL:-info}"
LOG_FILE_NAME="${LOG_FILE_NAME:-embulk.log}"
LOG_PATH="--log ${LOG_PATH:-/etc/embulk/log/}${LOG_FILE_NAME}"
embulk run $CONFIG $RESUME $LOG_PATH $LOG_LEVEL $BUNDLE
