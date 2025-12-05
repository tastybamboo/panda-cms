# =====================================================================
# Panda CMS — Optimised CI Dockerfile (amd64 only)
# Ubuntu 24.04 + Ruby 3.4.7 (mise) + PostgreSQL 17 + Chrome Stable
# =====================================================================

# We *must* force amd64 because Chrome is only published for x86_64
FROM --platform=linux/amd64 ubuntu:24.04 AS base

ENV DEBIAN_FRONTEND=noninteractive \
  LANG=C.UTF-8 \
  LC_ALL=C.UTF-8

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# ---------------------------------------------------------------------
# GLOBAL BASE DEPENDENCIES
# ---------------------------------------------------------------------
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
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

# =====================================================================
# STAGE 1 — Chrome Install (with isolated APT cache)
# =====================================================================
FROM base AS chrome

# Chrome signing key & repo
RUN wget -q https://dl.google.com/linux/linux_signing_key.pub \
  -O /usr/share/keyrings/google-linux-signing-key.pub && \
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-linux-signing-key.pub] \
  http://dl.google.com/linux/chrome/deb/ stable main" \
  > /etc/apt/sources.list.d/google-chrome.list

# Install Chrome using *dedicated* APT cache
RUN --mount=type=cache,target=/var/cache/apt-chrome \
  echo 'APT::Acquire::Retries "5";' > /etc/apt/apt.conf.d/80-retries && \
  apt-get update && \
  apt-get install -y --no-install-recommends google-chrome-stable && \
  rm -rf /var/lib/apt/lists/*

# Chrome runtime dependencies (Ubuntu 24.04)
RUN apt-get update && apt-get install -y --no-install-recommends \
  libasound2t64 \
  libatk1.0-0t64 \
  libatk-bridge2.0-0t64 \
  libcairo2 \
  libcups2t64 \
  libdbus-1-3 \
  libexpat1 \
  libfontconfig1 \
  libfreetype6 \
  libglib2.0-0 \
  libgtk-3-0t64 \
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
  fonts-liberation \
  xdg-utils \
  dbus-x11 \
  && rm -rf /var/lib/apt/lists/*

# Stub dbus so Chrome 142+ doesn’t crash
RUN mkdir -p /run/dbus && \
  touch /run/dbus/system_bus_socket && \
  echo -e '#!/bin/sh\nexit 0' > /usr/bin/dbus-daemon && chmod +x /usr/bin/dbus-daemon

# Symlinks so Cuprite detects Chrome as “chromium”
RUN ln -sf /usr/bin/google-chrome /usr/bin/chromium && \
  ln -sf /usr/bin/google-chrome /usr/bin/chromium-browser

# =====================================================================
# STAGE 2 — PostgreSQL Install (separate APT cache)
# =====================================================================
FROM base AS postgres

RUN --mount=type=cache,target=/var/cache/apt-pg \
  apt-get update && \
  apt-get install -y --no-install-recommends gnupg curl ca-certificates && \
  curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
  | gpg --dearmor -o /usr/share/keyrings/pgdg.gpg && \
  echo "deb [signed-by=/usr/share/keyrings/pgdg.gpg] \
  http://apt.postgresql.org/pub/repos/apt noble-pgdg main" \
  > /etc/apt/sources.list.d/pgdg.list

# Create postgres user/group
RUN groupadd -r postgres && useradd -r -g postgres postgres

RUN --mount=type=cache,target=/var/cache/apt \
  apt-get update && \
  apt-get install -y postgresql-17 postgresql-client-17 && \
  rm -rf /var/lib/apt/lists/*

# Prepare PGDATA
RUN rm -rf /var/lib/postgresql/17/main && \
  mkdir -p /var/lib/postgresql/17/main && \
  chown -R postgres:postgres /var/lib/postgresql/17 && \
  mkdir -p /run/postgresql && \
  chown -R postgres:postgres /run/postgresql && \
  chmod 775 /run/postgresql

# Init DB
RUN su postgres -c "/usr/lib/postgresql/17/bin/initdb -D /var/lib/postgresql/17/main"

# =====================================================================
# STAGE 3 — Ruby Install via mise (with persistent compile cache)
# =====================================================================
FROM base AS ruby

ENV MISE_DATA_DIR="/mise" \
  MISE_CONFIG_DIR="/mise" \
  MISE_CACHE_DIR="/mise/cache" \
  PATH="/mise/shims:/root/.local/bin:${PATH}"

RUN curl https://mise.run | sh && \
  echo 'eval "$(${HOME}/.local/bin/mise activate bash)"' >> /root/.bashrc

# Install Ruby with warm build cache
RUN --mount=type=cache,target=/mise/cache \
  mise install ruby@3.4.7 && \
  mise use --global ruby@3.4.7

RUN gem install bundler -v "~> 2.7"

# =====================================================================
# FINAL STAGE — Assemble everything into one runtime image
# =====================================================================
FROM base

# Import components from earlier stages
COPY --from=chrome   /usr/bin/google-chrome*      /usr/bin/
COPY --from=chrome   /usr/bin/chromium*           /usr/bin/
COPY --from=chrome   /usr/bin/google-chrome       /usr/bin/google-chrome
COPY --from=chrome   /usr/bin/chromium            /usr/bin/chromium
COPY --from=chrome   /usr/bin/chromium-browser    /usr/bin/chromium-browser
COPY --from=chrome   /opt/google                  /opt/google
COPY --from=postgres /usr/lib/postgresql          /usr/lib/postgresql
COPY --from=postgres /usr/share/postgresql        /usr/share/postgresql
COPY --from=postgres /var/lib/postgresql          /var/lib/postgresql
COPY --from=ruby     /mise                        /mise
COPY --from=ruby     /root/.local                 /root/.local

ENV PATH="/mise/shims:/root/.local/bin:/usr/lib/postgresql/17/bin:${PATH}"

# Install runtime service scripts
COPY docker/ci/start-services.sh /usr/local/bin/start-services
COPY docker/ci/stop-services.sh  /usr/local/bin/stop-services
RUN chmod +x /usr/local/bin/start-services /usr/local/bin/stop-services

WORKDIR /app
COPY . .

CMD ["bash"]
