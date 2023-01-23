#!/bin/bash
export DISPLAY=:99
export XAUTHORITY=${DATA_DIR}/.Xauthority

LAT_V="$(wget -qO- https://api.github.com/repos/TheTorProject/gettorbrowser/releases | jq -r '.[].tag_name' | grep "linux64-" | cut -d '-' -f2)"
CUR_V="$(cat ${DATA_DIR}/application.ini | grep -E "^Version=[0-9].*" | cut -d '=' -f2)"
if [ -z "$CUR_V" ]; then
	if [ "${TOR_V}" == "latest" ]; then
		LAT_V="12.0.1"
	else
		LAT_V="$TOR_V"
	fi
else
	if [ "${TOR_V}" == "latest" ]; then
		LAT_V="$CUR_V"
		if [ -z "$LAT_V" ]; then
			echo "Something went horribly wrong with version detection, putting container into sleep mode..."
			sleep infinity
		fi
	else
		LAT_V="$TOR_V"
	fi
fi

rm ${DATA_DIR}/Tor-Browser-*.tar.xz 2>/dev/null

if [ -z "$CUR_V" ]; then
	echo "---Tor-Browser not installed, installing---"
	cd ${DATA_DIR}
	if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/Tor-Browser-${LAT_V}.tar.xz "https://github.com/TheTorProject/gettorbrowser/releases/download/linux64-${LAT_V}/tor-browser-linux64-${LAT_V}_ALL.tar.xz" ; then
		echo "---Sucessfully downloaded Tor-Browser---"
	else
		echo "---Something went wrong, can't download Tor-Browser, putting container in sleep mode---"
		rm -f ${DATA_DIR}/Tor-Browser-${LAT_V}.tar.xz
		sleep infinity
	fi
	tar -C ${DATA_DIR} --strip-components=2 -xf ${DATA_DIR}/Tor-Browser-${LAT_V}.tar.xz
	rm -f ${DATA_DIR}/Tor-Browser-${LAT_V}.tar.xz
elif [ "$CUR_V" != "$LAT_V" ]; then
	echo "---Version missmatch, installed v$CUR_V, downloading and installing latest v$LAT_V...---"
    cd ${DATA_DIR}
	mkdir -p /tmp/profile
	cp -R ${DATA_DIR}/TorBrowser/Data/Browser /tmp/profile/
	if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/Tor-Browser-${LAT_V}.tar.xz "https://github.com/TheTorProject/gettorbrowser/releases/download/linux64-${LAT_V}/tor-browser-linux64-${LAT_V}_ALL.tar.xz" ; then
		echo "---Sucessfully downloaded Tor-Browser---"
	else
		echo "---Something went wrong, can't download Tor-Browser, putting container in sleep mode---"
		rm -f ${DATA_DIR}/Tor-Browser-${LAT_V}.tar.xz
		sleep infinity
	fi
	tar -C ${DATA_DIR} --strip-components=2 -xf ${DATA_DIR}/Tor-Browser-${LAT_V}.tar.xz
	rm -rf ${DATA_DIR}/TorBrowser/Data/Browser
	cp -R /tmp/profile/Browser ${DATA_DIR}/TorBrowser/Data/
	rm -f ${DATA_DIR}/Tor-Browser-${LAT_V}.tar.xz
	rm -rf /tmp/profile
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