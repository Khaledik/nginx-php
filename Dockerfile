# On utilise l'image de base Ubuntu 20.04
FROM ubuntu:20.04

# On desactive les etape post-installation interactive
ARG DEBIAN_FRONTEND noninteractive

# On mets a  jour  et on installe les dependances necessaires (nginx, php, supervisor)
RUN apt update && \
    apt install -y nginx php-fpm supervisor && \
    rm -rf /var/lib/apt/lists/* && \
    apt clean

# On defini les services php et nginx avec des variables ENV + NOM + CHEMIN :
# Variable qui contient le fichier de config par defaut 
ENV nginx_vhost /etc/nginx/sites-available/default
# Variable qui contient le fichier de config php
ENV php_conf /etc/php/7.4/fpm/php.ini
# Variable qui contient le fichier de config nginx
ENV nginx_conf /etc/nginx/nginx.conf
# Variable qui contient le fichier de config supervisor
ENV supervisor_conf /etc/supervisor/supervisord.conf

# On active php-fpm sur la configuration nginx de l'hote virtuel
# COPY ./conf/default ${nginx_vhost}
# On remplace la configuration cgi.fix_pathinfo=1 par cgi.fix_pathinfo=0 dans le fichier de config php.ini / sed est une fonction de traitement de texte permettant d'effectuer des opérations de recherche et de remplacement dans des fichiers texte.
# -i indique à sed de modifier directement le fichier.
# -e spécifie une expression (commande) à exécuter.
# EXEMPLE : RUN sed -i -e 's/ancien_motif/nouveau_motif/' fichier.txt
RUN sed -i -e 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' ${php_conf} && \
    echo "\ndaemon off;" >> ${nginx_conf}
# # Ajoute le string "ndaemon off;" à la fin du fichier de configuration ${NGINX_CONF}}



# On copie la config superviseur
COPY ./supervisord.conf ${supervisor_conf}

# On créer un nouveau dossier pour le fichier sock php-fpm on modifie ensuite la propriété du répertoire racine Web /var/www/html et du répertoire PHP-FPM /run/php en l'utilisateur par défaut www-data.
# On s'assurent que les répertoires nécessaires existent et ont les bonnes permissions pour que le serveur web puisse fonctionner correctement lorsqu'il est exécuté dans un conteneur Docker.
RUN mkdir -p /run/php && \
    chown -R www-data:www-data /var/www/html && \
    chown -R www-data:www-data /run/php

# On défini un volume de l'image personnalisée pour pouvoir monter tous ces répertoires sur la machine de l'hôte on lui indique ou les fichier seront stockés.
VOLUME ["/etc/nginx/sites-enabled", "/etc/nginx/certs", "/etc/nginx/conf.d", "/var/log/nginx", "/var/www/html"]

# On copie le script start.sh
COPY start.sh /start.sh
# On defini une commande par defaut qui sera exécutéé lorsque le conteneur est lancé
# Il permet de lancer le superviseur.
CMD ["./start.sh"]

# On cible les ports necessaires
EXPOSE 80 443