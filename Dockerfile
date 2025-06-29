FROM librebooking/librebooking:v3.0.1


# Labels
LABEL org.opencontainers.image.title="LibreBooking Demo"
LABEL org.opencontainers.image.description="LibreBooking demo - not for production use"
LABEL org.opencontainers.image.licenses="GPL-3.0"
LABEL org.opencontainers.image.authors="schirmer@ipfdd.de"

# Set entrypoint
COPY entrypoint.sh /usr/local/bin/
RUN  chmod +x /usr/local/bin/entrypoint.sh


# Update and install required debian packages
ENV DEBIAN_FRONTEND=noninteractive
RUN set -ex; \
    apt-get update; \
    apt-get upgrade --yes; \
    apt-get install --yes --no-install-recommends \
      cron \
      gettext \
      mariadb-common \
      mariadb-server \
      mariadb-client; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*


# Get database basics and restoration script
RUN mkdir -p /setup/backup;
COPY ./setup/init.sql /setup/init.sql
COPY ./setup/announcements.sql /setup/announcements.sql
COPY ./setup/init-database.sh /setup/init-database.sh
RUN chmod +x /setup/init-database.sh

COPY ./setup/reset-container.sh /setup/reset-container.sh
RUN chmod +x /setup/reset-container.sh

COPY ./setup/reset-container-cron /etc/cron.d/reset-container-cron
RUN chmod 0644 /etc/cron.d/reset-container-cron && \
    crontab /etc/cron.d/reset-container-cron


# Copy images for sample data
COPY images/resource1.jpg /var/www/html/Web/uploads/images/resource1.jpg
COPY images/resource2.jpg /var/www/html/Web/uploads/images/resource2.jpg
RUN set -ex; \
    chown -R www-data:www-data /var/www/html/Web/uploads/images;


# Environment
WORKDIR    /
VOLUME     /config
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD        ["apache2-foreground"]