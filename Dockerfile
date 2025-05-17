##################
# BUILD STEP
##################
FROM ubuntu:24.04 AS builder

# avoid prompts during install
ENV DEBIAN_FRONTEND=noninteractive

# 1) Install Python3, pip (so we have /usr/bin/python3), and the tools to run debinstall.sh
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      xz-utils \
      curl \
      dirmngr \
      gnupg \
      python3 \
      python3-pip \
      python3-dev \
      dpkg-dev \
      debhelper \
      apt-utils && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/odoo

RUN mkdir -p /usr/src/debian

# 2) Copy in Odoo’s installer script + control file, then install deps
COPY setup/debinstall.sh ./debinstall.sh
COPY debian/control /usr/src/debian/control

RUN chmod +x debinstall.sh && \
    ./debinstall.sh

# 3) (Optional) remove build‐only packages to slim down the image
RUN apt-get purge -y --auto-remove \
      python3-dev \
      dpkg-dev \
      debhelper \
      apt-utils && \
    rm -rf /var/lib/apt/lists/*

# 4) Create an unprivileged 'odoo' user
RUN useradd -m -d /opt/odoo -U -r -s /usr/sbin/nologin odoo

# 5) Copy your Odoo source and entrypoint
COPY .             /opt/odoo
COPY entrypoint.sh /entrypoint.sh

# 6) Make entrypoint executable and fix ownership
RUN chmod +x /entrypoint.sh && \
    chown -R odoo:odoo /opt/odoo /entrypoint.sh

# 7) Switch to the odoo user
USER odoo
WORKDIR /opt/odoo

EXPOSE 8069

# 8) Launch via your entrypoint (which enforces --config=…)
ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]