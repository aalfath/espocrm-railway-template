# EspoCRM for Railway: web app (Apache), job daemon and WebSocket server in one service.
# They must share data/ and custom/, and a Railway volume belongs to one service only.
FROM espocrm/espocrm:10.1.4-apache@sha256:5f8fa9a708893b9fbfe55a778f24c952a6a73b94c97fb126eccd21aa936c878c

# Keep a copy of the image's writable folders so start.sh can seed an empty volume
# (and add new default files after an update without overwriting yours).
RUN set -eux; \
    mkdir -p /usr/src/espocrm-defaults; \
    cp -a /var/www/html/data /usr/src/espocrm-defaults/data; \
    cp -a /var/www/html/custom /usr/src/espocrm-defaults/custom; \
    cp -a /var/www/html/client/custom /usr/src/espocrm-defaults/client-custom; \
    rm -f /var/www/html/EspoCRM.zip

COPY railway/websocket-proxy.conf /etc/apache2/conf-available/espocrm-websocket.conf
COPY railway/start.sh /usr/local/bin/railway-start.sh
COPY railway/apache2-railway /usr/local/bin/apache2-railway
RUN chmod 755 /usr/local/bin/railway-start.sh /usr/local/bin/apache2-railway && a2enconf espocrm-websocket

ENV ESPOCRM_STORAGE_DIR=/espocrm-storage
EXPOSE 80

ENTRYPOINT ["/usr/local/bin/railway-start.sh"]
CMD ["apache2-railway"]
