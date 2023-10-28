#!/bin/bash
adduser $SSH_USER --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password
echo "$SSH_USER:$SSH_PASSWORD" | chpasswd
mkdir -p /home/$SSH_USER/.ssh
chmod -R go= /home/$SSH_USER/.ssh
echo $PRIVATE_KEY >> /home/$SSH_USER/.ssh/id_ed25519
chown -R $SSH_USER:$SSH_USER /home/$SSH_USER/.ssh
chmod 600 /home/$SSH_USER/.ssh/id_ed25519
sed -i "s/^ikey =.*/ikey = $DUO_IKEY/" /etc/duo/login_duo.conf
sed -i "s/^skey =.*/skey = $DUO_SKEY/" /etc/duo/login_duo.conf
sed -i "s/^host =.*/host = $DUO_HOST/" /etc/duo/login_duo.conf
sed -i "s/^#*AllowUsers .*/AllowUsers $SSH_USER/" /etc/ssh/sshd_config
/usr/sbin/sshd -D