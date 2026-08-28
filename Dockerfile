FROM ubuntu:26.04

# ------------------------------------------------------------------------------
# Environment
ENV TZ=Asia/Ho_Chi_Minh
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHON_VERSION=3.14.2
ENV PYTHON_BIN=/usr/local/bin/python3.14
# Java
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV JRE_HOME=${JAVA_HOME}
ENV PATH=${JAVA_HOME}/bin:/usr/local/bin:${PATH}
# ------------------------------------------------------------------------------
# Base system + build deps
RUN apt-get update && apt-get install -y \
    software-properties-common \
    sudo \
    wget \
    make \
    gcc \
    git \
    nano \
    vim \
    tree \
    ca-certificates \
    lsb-release \
    libsystemd-dev \
    pkg-config \
    libssl-dev \
    libbz2-dev \
    libkrb5-dev \
    libffi-dev \
    openjdk-17-jdk \
    zlib1g-dev \
    libreadline-dev \
    libsqlite3-dev \
    liblzma-dev \
    tk-dev \
    uuid-dev \
    build-essential \
    libncurses-dev \
    && add-apt-repository universe \
    && add-apt-repository multiverse \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
# ------------------------------------------------------------------------------
# Create user
RUN useradd -m akatsukihina && \
    usermod -aG sudo akatsukihina && \
    echo "akatsukihina ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    mkdir -p /home/akatsukihina/.ssh && \
    chown -R akatsukihina:akatsukihina /home/akatsukihina
# ------------------------------------------------------------------------------
# Setup java 
RUN echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> /etc/profile.d/java.sh && \
    echo 'export JRE_HOME=$JAVA_HOME' >> /etc/profile.d/java.sh && \
    echo 'export PATH=$JAVA_HOME/bin:$PATH' >> /etc/profile.d/java.sh && \
    chmod +x /etc/profile.d/java.sh
# ------------------------------------------------------------------------------
# Build Python
WORKDIR /tmp
RUN wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz && \
    tar xJf Python-${PYTHON_VERSION}.tar.xz && \
    cd Python-${PYTHON_VERSION} && \
    ./configure --enable-optimizations && \
    make altinstall

# ------------------------------------------------------------------------------
# Install pip
RUN ${PYTHON_BIN} -m ensurepip --upgrade && \
    ${PYTHON_BIN} -m pip install --upgrade pip setuptools wheel

# ------------------------------------------------------------------------------
# Set python3 -> python3.14
RUN ln -sf ${PYTHON_BIN} /usr/bin/python3

# ------------------------------------------------------------------------------
# Ansible runtime env
ENV ANSIBLE_PYTHON_INTERPRETER=${PYTHON_BIN}
ENV PATH="/usr/local/bin:${PATH}"

# ------------------------------------------------------------------------------
# Create requirements.txt INSIDE image
RUN cat <<'EOF' > /tmp/requirements.txt
ansible==9.13.0
passlib==1.7.4
bcrypt>=4.1.2
cryptography==45.0.2
pyyaml>=6.0.1
aiobotocore
aiohttp
aiokafka[gssapi]
fastavro
azure-servicebus
dpath
kafka-python; python_version <= "3.14"
kafka-python-ng;  python_version >= "3.14"
psycopg[binary,pool]
systemd-python; sys_platform != 'darwin'
watchdog>=5.0.0  # types
xxhash
jmespath==1.0.1
netaddr==1.3.0
PyYAML>=6.0
EOF

# ------------------------------------------------------------------------------
# Install Python dependencies
RUN ${PYTHON_BIN} -m pip install --no-cache-dir -r /tmp/requirements.txt

# ------------------------------------------------------------------------------
# Install ansible tools

RUN ${PYTHON_BIN} -m pip install 'ansible-navigator[ansible-core]'
RUN ansible-galaxy collection install \
    ansible.eda \
    ansible.utils
RUN ${PYTHON_BIN} -m pip install ansible-rulebook
# ------------------------------------------------------------------------------
# Kubespray
USER akatsukihina
WORKDIR /home/akatsukihina/ansible

COPY ./ /home/akatsukihina/ansible/eda
# ------------------------------------------------------------------------------
# Default
CMD ["/bin/bash"]

