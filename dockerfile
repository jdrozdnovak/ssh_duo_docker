
# Use the official image as a parent image
FROM ubuntu

# Update the system
RUN apt update
RUN apt upgrade -y
RUN apt install -y openssh-server libssl-dev curl gnupg2 gnupg

#get duo
RUN echo "deb [arch=amd64] https://pkg.duosecurity.com/Ubuntu jammy main" >> /etc/apt/sources.list
RUN curl -s https://duo.com/DUO-GPG-PUBLIC-KEY.asc | gpg --dearmor -o  /etc/apt/trusted.gpg.d/duo.gpg

# Install OpenSSH Server
RUN apt update
RUN apt install -y duo-unix

# Set up configuration for SSH
RUN rm /etc/ssh/ssh_host_*
RUN ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ""
RUN ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""
RUN mkdir /var/run/sshd
# RUN mkdir /run/sshd
RUN awk '$5 >= 3071' /etc/ssh/moduli > /etc/ssh/moduli.safe
RUN mv /etc/ssh/moduli.safe /etc/ssh/moduli
RUN sed -i 's/^\#HostKey \/etc\/ssh\/ssh_host_\(rsa\|ed25519\)_key$/HostKey \/etc\/ssh\/ssh_host_\1_key/g' /etc/ssh/sshd_config
RUN echo -e "\n# Restrict key exchange, cipher, and MAC algorithms, as per sshaudit.com\n# hardening guide.\nKexAlgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org,gss-curve25519-sha256-,diffie-hellman-group16-sha512,gss-group16-sha512-,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256\nCiphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr\nMACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com\nHostKeyAlgorithms ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,sk-ssh-ed25519-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-256,rsa-sha2-256-cert-v01@openssh.com" > /etc/ssh/sshd_config.d/ssh-audit_hardening.conf
RUN sed -i 's/^#*Protocol .*/Protocol 2/' /etc/ssh/sshd_config
RUN sed -i 's/^#*PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
RUN sed -i 's/^#*PermitEmptyPasswords .*/PermitEmptyPasswords no/' /etc/ssh/sshd_config
RUN sed -i 's/^#*AllowAgentForwarding .*/AllowAgentForwarding no/' /etc/ssh/sshd_config
RUN sed -i 's/^#*AllowTcpForwarding .*/AllowTcpForwarding no/' /etc/ssh/sshd_config
RUN sed -i 's/^#*X11Forwarding .*/X11Forwarding no/' /etc/ssh/sshd_config
RUN sed -i 's/^#*PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
RUN sed -i 's/^#*LogLevel .*/LogLevel VERBOSE/' /etc/ssh/sshd_config
RUN echo "ForceCommand /usr/sbin/login_duo" >> /etc/ssh/sshd_config;
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile
COPY entry.sh /entry.sh
RUN chmod +x /entry.sh

# Expose the SSH port
EXPOSE 22

# Run SSH
CMD [/entry.sh]
