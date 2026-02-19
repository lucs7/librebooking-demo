FROM librebooking/librebooking:develop


# Labels
LABEL org.opencontainers.image.title="LibreBooking Demo"
LABEL org.opencontainers.image.description="LibreBooking demo - not for production use"
LABEL org.opencontainers.image.licenses="GPL-3.0"
LABEL org.opencontainers.image.authors="schirmer@ipfdd.de"

# Set entrypoint
COPY --chmod=755 entrypoint.sh /usr/local/bin/

# Switch to root user for package installation
USER root

# Update and install required debian packages
ENV DEBIAN_FRONTEND=noninteractive
RUN set -ex; \
    apt-get update; \
    apt-get install --yes --no-install-recommends -o Dpkg::Options::="--force-confold" \
      cron \
      gettext \
      mariadb-common \
      mariadb-server \
      mariadb-client; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# Create local /config directory as we will not mount one
RUN mkdir -p /config;    

# Get database basics and restoration script
RUN mkdir -p /setup/backup;
COPY ./setup/init.sql /setup/init.sql
COPY ./setup/announcements.sql /setup/announcements.sql
COPY --chmod=755 ./setup/init-database.sh /setup/init-database.sh

COPY --chmod=755 ./setup/reset-container.sh /setup/reset-container.sh

COPY --chmod=644 ./setup/reset-container-cron /etc/cron.d/reset-container-cron
RUN crontab /etc/cron.d/reset-container-cron


# Copy images for sample data
COPY images/resource1.jpg /var/www/html/Web/uploads/images/resource1.jpg
COPY images/resource2.jpg /var/www/html/Web/uploads/images/resource2.jpg
RUN set -ex; \
    chown -R www-data:www-data /var/www/html/Web/uploads/images;


# Environment
WORKDIR    /
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD        ["apache2-foreground"]