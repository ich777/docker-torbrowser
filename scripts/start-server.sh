#!/bin/bash
export DISPLAY=:99
export XAUTHORITY=${DATA_DIR}/.Xauthority

CUR_V=$(${DATA_DIR}/firefox --version 2>/dev/null | grep -E "^[0-9]*")

if [[ "$CUR_V" == *" 102.13"* ]]; then
  unset CUR_V
fi

rm ${DATA_DIR}/Tor-Browser-*.tar.xz 2>/dev/null

if [ -z "$CUR_V" ]; then
  DL_URL="$(wget -qO- https://aus1.torproject.org/torbrowser/update_3/release/downloads.json | jq -r '.downloads."linux-x86_64".ALL.binary')"
  echo "---Tor-Browser not installed, installing---"
  cd ${DATA_DIR}
  if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/Tor-Browser-${LAT_V}.tar.xz "${DL_URL}" ; then
    echo "---Sucessfully downloaded Tor-Browser---"
  else
    echo "---Something went wrong, can't download Tor-Browser, putting container in sleep mode---"
    rm -f ${DATA_DIR}/Tor-Browser-${LAT_V}.tar.xz
    sleep infinity
  fi
  tar -C ${DATA_DIR} --strip-components=2 -xf ${DATA_DIR}/Tor-Browser-${LAT_V}.tar.xz
  rm -f ${DATA_DIR}/Tor-Browser-${LAT_V}.tar.xz
fi

echo "---Preparing Server---"
echo "---Resolution check---"
if [ -z "${CUSTOM_RES_W} ]; then
	CUSTOM_RES_W=1024
fi
if [ -z "${CUSTOM_RES_H} ]; then
  CUSTOM_RES_H=768
fi

if [ "${CUSTOM_RES_W}" -le 1023 ]; then
  echo "---Width to low must be a minimal of 1024 pixels, correcting to 1024...---"
  CUSTOM_RES_W=1024
fi
if [ "${CUSTOM_RES_H}" -le 767 ]; then
  echo "---Height to low must be a minimal of 768 pixels, correcting to 768...---"
  CUSTOM_RES_H=768
fi
echo "---Checking for old logfiles---"
find $DATA_DIR -name "XvfbLog.*" -exec rm -f {} \;
find $DATA_DIR -name "x11vncLog.*" -exec rm -f {} \;
echo "---Checking for old display lock files---"
rm -rf /tmp/.X99*
rm -rf /tmp/.X11*
rm -rf ${DATA_DIR}/.vnc/*.log ${DATA_DIR}/.vnc/*.pid
chmod -R ${DATA_PERM} ${DATA_DIR}
if [ -f ${DATA_DIR}/.vnc/passwd ]; then
  chmod 600 ${DATA_DIR}/.vnc/passwd
fi
screen -wipe 2&>/dev/null

echo "---Starting TurboVNC server---"
vncserver -geometry ${CUSTOM_RES_W}x${CUSTOM_RES_H} -depth ${CUSTOM_DEPTH} :99 -rfbport ${RFB_PORT} -noxstartup ${TURBOVNC_PARAMS} 2>/dev/null
sleep 2
echo "---Starting Fluxbox---"
/opt/scripts/start-fluxbox.sh &
sleep 2
echo "---Starting noVNC server---"
websockify -D --web=/usr/share/novnc/ --cert=/etc/ssl/novnc.pem ${NOVNC_PORT} localhost:${RFB_PORT}
sleep 2

echo "---Starting Tor-Browser---"
cd ${DATA_DIR}
${DATA_DIR}/start-tor-browser --display=:99 --P ${USER} --setDefaultBrowser ${EXTRA_PARAMETERS}