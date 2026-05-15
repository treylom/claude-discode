# thiscode dogfood sandbox — WSL Ubuntu 20.04 mimic
#
# Build:  docker build -t thiscode-sandbox -f sandbox/Dockerfile .
# Run:    docker run -it --rm -v "$PWD":/thiscode thiscode-sandbox bash
#
# Inside the container, run:
#   bash /thiscode/tests/dogfood/run-all.sh

FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm-256color \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates curl wget git jq sudo build-essential \
        python3 python3-pip python3-venv \
        ripgrep grep gawk perl \
        tmux openssh-client && \
    rm -rf /var/lib/apt/lists/*

# nvm + Node LTS — mimics install.sh Step 3
ENV NVM_DIR=/root/.nvm
RUN mkdir -p "$NVM_DIR" && \
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash && \
    . "$NVM_DIR/nvm.sh" && \
    nvm install --lts && \
    nvm use --lts && \
    ln -sf "$(which node)" /usr/local/bin/node && \
    ln -sf "$(which npm)" /usr/local/bin/npm

# Placeholder for Claude Code install — dogfood scenarios install on demand
WORKDIR /thiscode

CMD ["bash"]
