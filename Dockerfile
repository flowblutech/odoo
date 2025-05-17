##################
# BUILD STEP
##################
FROM ubuntu:24.04 AS builder

# avoid prompts during install
ENV DEBIAN_FRONTEND=noninteractive

# 1) Install Python3, pip (so we have /usr/bin/python3), and the tools to run debinstall.sh
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      apt-utils \
      ca-certificates \
      curl \
      debhelper \
      dirmngr \
      dpkg-dev \
      fonts-noto-cjk \
      gnupg \
      libssl-dev \
      node-less \
      npm \
      python3 \
      python3-dev \
      python3-magic \
      python3-odf \
      python3-pdfminer \
      python3-phonenumbers \
      python3-pip \
      python3-pyldap \
      python3-setuptools \
      python3-slugify \
      python3-watchdog \
      python3-xlwt \
      xz-utils && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/odoo

RUN mkdir -p /usr/src/debian

# 2) Copy in Odoo’s installer script + control file, then install deps
COPY setup/debinstall.sh ./debinstall.sh
COPY debian/control /usr/src/debian/control

RUN chmod +x debinstall.sh \
 && ./debinstall.sh \
 \
 # now drop all the build-only packages and clean up apt caches
 && apt-get purge -y --auto-remove \
      python3-dev \
      dpkg-dev \
      debhelper \
      apt-utils \
 && rm -rf /var/lib/apt/lists/* \
 \
 # finally, add our unprivileged odoo user
 && useradd -m -d /opt/odoo -U -r -s /usr/sbin/nologin odoo

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
