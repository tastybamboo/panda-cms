# =====================================================================
# Panda CMS — CI Environment
# Ubuntu 24.04 + Ruby via mise + PostgreSQL 17 + Chrome Stable
# =====================================================================

FROM --platform=linux/amd64 ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
  LANG=C.UTF-8 \
  LC_ALL=C.UTF-8

# Use bash everywhere (mise requires this)
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# ---------------------------------------------------------------------
# Base system & Ruby build dependencies
# ---------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
  tini \
  ca-certificates \
  curl \
  wget \
  git \
  unzip \
  gnupg \
  build-essential \
  software-properties-common \
  lsb-release \
  procps \
  libreadline-dev \
  zlib1g-dev \
  libssl-dev \
  libyaml-dev \
  && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/usr/bin/tini", "--"]

# ---------------------------------------------------------------------
# PostgreSQL 17
# ---------------------------------------------------------------------
RUN curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
  | gpg --dearmor -o /usr/share/keyrings/pgdg.gpg && \
  echo "deb [signed-by=/usr/share/keyrings/pgdg.gpg] \
  http://apt.postgresql.org/pub/repos/apt noble-pgdg main" \
  > /etc/apt/sources.list.d/pgdg.list && \
  apt-get update && \
  apt-get install -y postgresql-17 postgresql-client-17 && \
  rm -rf /var/lib/apt/lists/*

ENV PATH="/usr/lib/postgresql/17/bin:${PATH}"

# proper initdb setup
RUN rm -rf /var/lib/postgresql/17/main && \
  mkdir -p /var/lib/postgresql/17/main && \
  chown -R postgres:postgres /var/lib/postgresql/17 && \
  mkdir -p /run/postgresql && \
  chown -R postgres:postgres /run/postgresql && \
  chmod 775 /run/postgresql && \
  su postgres -c "/usr/lib/postgresql/17/bin/initdb -D /var/lib/postgresql/17/main"

# ---------------------------------------------------------------------
# Google Chrome Stable
# ---------------------------------------------------------------------
RUN wget -q https://dl.google.com/linux/linux_signing_key.pub \
  -O /usr/share/keyrings/google-linux-signing-key.pub && \
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-linux-signing-key.pub] \
  http://dl.google.com/linux/chrome/deb/ stable main" \
  > /etc/apt/sources.list.d/google-chrome.list && \
  apt-get update && \
  apt-get install -y google-chrome-stable && \
  rm -rf /var/lib/apt/lists/*

# Chrome runtime dependencies for Ubuntu 24.04 (Noble)
RUN apt-get update && apt-get install -y --no-install-recommends \
  libasound2t64 \
  libatk1.0-0 \
  libatk-bridge2.0-0 \
  libcairo2 \
  libcups2 \
  libdbus-1-3 \
  libexpat1 \
  libfontconfig1 \
  libfreetype6 \
  libglib2.0-0 \
  libgtk-3-0 \
  libnspr4 \
  libnss3 \
  libpango-1.0-0 \
  libpangocairo-1.0-0 \
  libx11-6 \
  libx11-xcb1 \
  libxcb1 \
  libxcomposite1 \
  libxcursor1 \
  libxdamage1 \
  libxext6 \
  libxfixes3 \
  libxi6 \
  libxrandr2 \
  libxrender1 \
  libxshmfence1 \
  libxss1 \
  libxtst6 \
  libgbm1 \
  libdrm2 \
  libu2f-udev \
  libwoff1 \
  libffi8 \
  dbus-x11 \
  xdg-utils \
  fonts-liberation \
  && rm -rf /var/lib/apt/lists/*

# Fake DBus so Chrome 142+ doesn't crash
RUN mkdir -p /run/dbus && \
  touch /run/dbus/system_bus_socket && \
  echo -e '#!/bin/sh\nexit 0' > /usr/bin/dbus-daemon && \
  chmod +x /usr/bin/dbus-daemon

# Symlinks so Ferrum/Cuprite detect Chrome correctly
RUN ln -sf /usr/bin/google-chrome /usr/bin/chromium && \
  ln -sf /usr/bin/google-chrome /usr/bin/chromium-browser

# ---------------------------------------------------------------------
# mise + Ruby 3.4.7
# ---------------------------------------------------------------------
ENV MISE_DATA_DIR="/mise" \
  MISE_CONFIG_DIR="/mise" \
  MISE_CACHE_DIR="/mise/cache" \
  PATH="/mise/shims:/root/.local/bin:${PATH}"

RUN curl https://mise.run | sh
RUN echo 'eval "$(${HOME}/.local/bin/mise activate bash)"' >> /root/.bashrc

RUN mise install ruby@3.4.7
RUN mise use --global ruby@3.4.7

RUN gem install bundler -v "~> 2.7"

# ---------------------------------------------------------------------
# CI helper scripts
# ---------------------------------------------------------------------
COPY docker/ci/start-services.sh /usr/local/bin/start-services
COPY docker/ci/stop-services.sh  /usr/local/bin/stop-services
RUN chmod +x /usr/local/bin/start-services /usr/local/bin/stop-services

# ---------------------------------------------------------------------
# Instantiate app
# ---------------------------------------------------------------------
WORKDIR /app
COPY . .

CMD ["bash"]
