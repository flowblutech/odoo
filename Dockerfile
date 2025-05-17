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
    # Install wkhtmltopdf
    curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.jammy_amd64.deb && \
    echo 967390a759707337b46d1c02452e2bb6b2dc6d59 wkhtmltox.deb | sha1sum -c - && \
    apt-get install -y --no-install-recommends ./wkhtmltox.deb && \
    # Cleanup
    rm -rf /var/lib/apt/lists/* wkhtmltox.deb


WORKDIR /usr/src/odoo

RUN mkdir -p /usr/src/debian

# 2) Copy in Odoo’s installer script + control file, then install deps
COPY setup/debinstall.sh ./debinstall.sh
COPY debian/control /usr/src/debian/control

ARG ODOO_UID=999
ARG ODOO_GID=999

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
 && groupadd --gid "${ODOO_GID}" odoo \
  \
 && useradd \
          --uid "${ODOO_UID}" \
          --gid "${ODOO_GID}" \
          --home-dir /opt/odoo \
          --create-home \
          --shell /usr/sbin/nologin \
          --system \
          odoo

# 5) Copy your Odoo source and entrypoint
COPY .             /opt/odoo
COPY entrypoint.sh /entrypoint.sh

# 6) Make entrypoint executable and fix ownership
RUN chmod +x /entrypoint.sh && \
    chown -R odoo:odoo /opt/odoo /entrypoint.sh

EXPOSE 8069

# Set permissions and Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
RUN mkdir -p /var/lib/odoo /mnt/extra-addons /configs \
 && chown -R odoo:odoo /var/lib/odoo /mnt/extra-addons /configs
VOLUME [ "/var/lib/odoo", "/mnt/extra-addons", "/configs" ]

# 7) Switch to the odoo user
USER odoo
WORKDIR /opt/odoo

# 8) Launch via your entrypoint (which enforces --config=…)
#ENTRYPOINT [ "/entrypoint.sh", "--config=/configs/odoo.conf", "--addons-path=/opt/odoo/addons,/mnt/extra-addons", "--data-dir=/var/lib/odoo" ]
ENTRYPOINT [ "/entrypoint.sh" ]
