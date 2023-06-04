# Tor Browser in Docker optimized for Unraid
This container will download and install Tor Browser in the preferred version and language.

RESOLUTION: You can also change the resolution from the WebGUI, to do that simply click on 'Show more settings...' (on a resolution change it can occour that the screen is not filled entirely with the Tor Browser window, simply restart the container and it will be fullscreen again).

## Env params
| Name | Value | Example |
| --- | --- | --- |
| DATA_DIR | Folder for Tor Browser | /torbrowser |
| TOR_V | Enter your preferred Tor Browser version or 'latest' to install the latest version | latest |
| CUSTOM_RES_W | Enter your preferred screen width | 1280 |
| CUSTOM_RES_H | Enter your preferred screen height | 768 |
| UID | User Identifier | 99 |
| GID | Group Identifier | 100 |
| UMASK | Umask value | 000 |
| DATA_PERM | Data permissions for /torbrowser folder | 770 |

## Run example
```
docker run --name Tor-Browser -d \
	-p 8080:8080 \
	--env 'TOR_V=latest' \
	--env 'CUSTOM_RES_W=1280' \
	--env 'CUSTOM_RES_H=768' \
	--env 'UID=99' \
	--env 'GID=100' \
	--env 'UMASK=000' \
	--env 'DATA_PERM=770' \
	--volume /path/to/torbrowser:/torbrowser \
	ich777/torbrowser
```
### Webgui address: http://[SERVERIP]:[PORT]/vnc.html?autoconnect=true

## Set VNC Password:
 Please be sure to create the password first inside the container, to do that open up a console from the container (Unraid: In the Docker tab click on the container icon and on 'Console' then type in the following):

1) **su $USER**
2) **vncpasswd**
3) **ENTER YOUR PASSWORD TWO TIMES AND PRESS ENTER AND SAY NO WHEN IT ASKS FOR VIEW ACCESS**

Unraid: close the console, edit the template and create a variable with the `Key`: `TURBOVNC_PARAMS` and leave the `Value` empty, click `Add` and `Apply`.

All other platforms running Docker: create a environment variable `TURBOVNC_PARAMS` that is empty or like this:
```
    --env 'TURBOVNC_PARAMS=-securitytypes VNC'
```

This Docker was mainly edited for better use with Unraid, if you don't use Unraid you should definitely try it!

#### Support Thread: https://forums.unraid.net/topic/83786-support-ich777-application-dockers/
