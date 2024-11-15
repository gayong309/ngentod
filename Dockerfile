FROM ubuntu:22.04

ARG PASSWORD=rootuser
ENV DEBIAN_FRONTEND=noninteractive
ENV PLAYIT_CONFIG=/root/.playit/config.yml
ENV PLAYIT_LOG=/root/.playit/logs/agent.log

# Install packages
RUN apt update && apt upgrade -y && apt install -y \
    ssh wget vim curl python3 python3-pip python3-venv \
    mariadb-server mariadb-client nginx gnupg \
    && apt clean

# Install Python requests module
RUN pip3 install requests

# Add Playit.gg repository and install Playit.gg
RUN curl -SsL https://playit-cloud.github.io/ppa/key.gpg | gpg --dearmor | \
    tee /etc/apt/trusted.gpg.d/playit.gpg >/dev/null \
    && echo "deb [signed-by=/etc/apt/trusted.gpg.d/playit.gpg] https://playit-cloud.github.io/ppa/data ./" | tee /etc/apt/sources.list.d/playit-cloud.list \
    && apt update \
    && apt install -y playit \
    && mkdir /run/sshd

# Install Docker
RUN curl -fsSL https://get.docker.com -o get-docker.sh \
    && sh get-docker.sh \
    && rm get-docker.sh

# Install Docker Compose
RUN curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose

# Setup Pterodactyl Panel
RUN mkdir -p /var/www/pterodactyl \
    && cd /var/www/pterodactyl \
    && curl -LO https://github.com/pterodactyl/panel/releases/download/v1.8.1/panel.tar.gz \
    && tar -xzvf panel.tar.gz \
    && rm panel.tar.gz

# Add setup script and Python script
COPY setup.sh /setup.sh
RUN chmod +x /setup.sh

# Configure SSH
RUN echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config \
    && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config \
    && echo root:${PASSWORD} | chpasswd \
    && echo "#!/bin/bash" > /docker.sh \
    && echo "playit --config $PLAYIT_CONFIG &" >> /docker.sh \
    && echo "sleep 5" >> /docker.sh \
    && echo '/usr/sbin/sshd -D' >> /docker.sh \
    && chmod +x /docker.sh

EXPOSE 22

CMD ["/bin/bash", "/docker.sh"]
