#!/bin/bash

mkdir -p /var/run/sshd

DISABLE_UNIX_PWD=1

IMAGE=$(< /lab-name)
HOME=/home/ubuntu/
DESKTOP=$HOME/Desktop/

LAB_NAME=`basename ${IMAGE}`
LAB_TOOLS=/$LAB_NAME/tools/
LAB_UNIX_PWD=$LAB_TOOLS/.lab_unix_pwd
LAB_VNC_PWD=$LAB_TOOLS/.lab_login_pwd

# create an ubuntu user
id -u ubuntu &>/dev/null || useradd --create-home --shell /bin/bash --user-group --groups adm,sudo ubuntu

sudo mkdir $DESKTOP
sudo cp /lab.desktop $DESKTOP/${LAB_NAME}.desktop
sudo chown ubuntu:ubuntu -R $HOME/

UNIX_PASS=$(< $LAB_UNIX_PWD)
VNC_PASS=$(< $LAB_VNC_PWD)

[ -z "$UNIX_PASS" ] && UNIX_PASS=`pwgen -c -n -1 10` && echo $UNIX_PASS > $LAB_UNIX_PWD
[ -z "$VNC_PASS" ] && VNC_PASS=`pwgen -c -n -1 10` && echo $VNC_PASS > $LAB_VNC_PWD
sudo chown ubuntu:ubuntu $LAB_UNIX_PWD $LAB_VNC_PWD

echo "Username: ubuntu Password: $UNIX_PASS VNC-Password: $VNC_PASS"

# VNC OASS
sudo -u ubuntu mkdir $HOME/.vnc/
sudo -u ubuntu x11vnc -storepasswd $VNC_PASS $HOME/.vnc/passwd

# UNIX PASS
echo "ubuntu:$UNIX_PASS" | chpasswd

# Lock UNIX Password?
[ $DISABLE_UNIX_PWD -eq 1 ] && passwd -l ubuntu

sudo -u ubuntu -i bash -c "mkdir -p $HOME/.config/pcmanfm/LXDE/ \
    && cp /usr/share/doro-lxde-wallpapers/desktop-items-0.conf $HOME/.config/pcmanfm/LXDE/"

cd /web && ./run.py > /var/log/web.log 2>&1 &
nginx -c /etc/nginx/nginx.conf

if [ -f /bin/tini ]; then
	exec /bin/tini -- /usr/bin/supervisord -n
else
	exec /usr/bin/supervisord -n
fi
