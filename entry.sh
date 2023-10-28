#!/bin/bash
if [ ! -f "/app/sshd_config/ssh_host_rsa_key" ]; then
    ssh-keygen -t rsa -b 4096 -f /app/sshd_config/ssh_host_rsa_key -N ""
fi

# Check for ED25519 key
if [ ! -f "/app/sshd_config/ssh_host_ed25519_key" ]; then
    ssh-keygen -t ed25519 -f /app/sshd_config/ssh_host_ed25519_key -N ""
fi
rm /etc/ssh/ssh_host_*
cp /app/sshd_config/ssh_host_rsa_key /etc/ssh/ssh_host_rsa_key
cp /app/sshd_config/ssh_host_ed25519_key /etc/ssh/ssh_host_ed25519_key
adduser $SSH_USER --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password
echo "$SSH_USER:$SSH_PASSWORD" | chpasswd
mkdir -p /home/$SSH_USER/.ssh
chmod -R go= /home/$SSH_USER/.ssh
echo $PRIVATE_KEY | base64 -d >> /home/$SSH_USER/.ssh/id_ed25519
chown -R $SSH_USER:$SSH_USER /home/$SSH_USER/.ssh
chmod 600 /home/$SSH_USER/.ssh/id_ed25519
sed -i "s/^ikey =.*/ikey = $DUO_IKEY/" /etc/duo/login_duo.conf
sed -i "s/^skey =.*/skey = $DUO_SKEY/" /etc/duo/login_duo.conf
sed -i "s/^host =.*/host = $DUO_HOST/" /etc/duo/login_duo.conf
sed -i "s/^#*AllowUsers .*/AllowUsers $SSH_USER/" /etc/ssh/sshd_config
/usr/sbin/sshd -D