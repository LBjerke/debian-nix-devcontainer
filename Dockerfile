FROM debian:stable

LABEL maintainer="X-Truder <dev@x-truder.net>"

# update and install base packages
RUN apt update -y
RUN apt -y install --no-install-recommends \
    curl \
    ca-certificates \
    xz-utils \
    sudo \
    git \
    ssh \
    gnupg2 \
    nano \
    vim-tiny \
    less \
    psmisc \
    procps \
    rsync \
    lsb-release \
    apt-transport-https \
    software-properties-common \
    dialog \
    locales \
    man-db \
    direnv \
    bash-completion

# create at least locae for en_US.UTF-8
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen

# create non-root user and group and add it sudoers
ARG USERNAME=user
ARG USER_UID=1000
ARG USER_GID=${USER_UID}
RUN groupadd --gid ${USER_GID} ${USERNAME} && \
    useradd -s /bin/bash --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} && \
    echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} && \
    chmod 0440 /etc/sudoers.d/${USERNAME}

# install nix
ARG NIX_INSTALL_SCRIPT=https://nixos.org/nix/install
RUN curl -L ${NIX_INSTALL_SCRIPT} | sudo -u user NIX_INSTALLER_NO_MODIFY_PROFILE=1 sh

# configure nix
ARG EXTRA_NIX_CONFIG=""
RUN mkdir -p /etc/nix && echo "sandbox = false\n$EXTRA_NIX_CONFIG" > /etc/nix/nix.conf

# install devcontainer extra profile and bashrc that loads direnv
COPY profile.sh /etc/profile.d/devcontainer.sh
COPY bash.bashrc /etc/bash.bashrc

# onbuild uid and gid fixes
ONBUILD ARG USERNAME=user
ONBUILD ARG USER_UID=1000
ONBUILD ARG USER_GID=${USER_UID}
ONBUILD ENV USER=${USERNAME}
ONBUILD RUN \
    set -x && \
    if [ -z ${USER_UID} ] || [ -z ${USER_UID} ] || [ -z ${USERNAME} ]; then exit 0; fi && \
    if [ "$(id -g ${USERNAME})" != "${USER_UID}" ] || [ "$(id -g ${USERNAME})" != "${USER_GID}" ]; then \
        groupmod -g ${USER_GID} user || true && \
        usermod -u ${USER_UID} -g ${USER_GID} ${USERNAME} && \
        chown -R ${USER_UID}:${USER_GID} /nix && \
        chown -R ${USER_UID}:${USER_GID} /home/${USERNAME}; \
    fi

# create volume for nix, this needs to be here, so permissions are correct
ONBUILD VOLUME /nix

# create volume for direnv
ONBUILD RUN sudo -u user mkdir -p /home/${USERNAME}/.local/share/direnv/allow
ONBUILD VOLUME /home/${USERNAME}/.local/share/direnv/allow