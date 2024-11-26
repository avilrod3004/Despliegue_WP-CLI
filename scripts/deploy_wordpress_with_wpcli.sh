#!/bin/bash

# Verificar que se ha ejecutado primero el script para instalar y configurar LAMP
if [ ! -f /var/log/lamp_installed.flag ]; then
    echo "ERROR: El entorno LAMP no está instalado. Ejecute primero el script "install_lamp.sh"." >&2
    exit 1
fi

# Cargar variables de entorno desde .env
if [ -f .env ]; then
    source .env
else
    echo "ERROR: No se ha encontrado el archivo .env" >&2
    exit 1
fi

# Validar que las variables están cargadas
if [[ -z "$DB_NAME" || -z "$DB_USER" || -z "$DB_PASSWORD" || -z "$WP_URL" || -z "$WP_TITLE" || -z "$WP_ADMIN_USER" || -z "$WP_ADMIN_PASSWORD" || -z "$WP_ADMIN_EMAIL" ]]; then
    echo "ERROR: Las variables DB_NAME, DB_USER, DB_PASSWORD, WP_URL, WP_TITLE, WP_ADMIN_USER, WP_ADMIN_PASSWORD o WP_ADMIN_EMAIL no están definidas en .env" >&2
    exit 1
fi

# Verificar permisos de superusuario
if ! sudo -v > /dev/null 2>&1; then
    echo "ERROR: Este script requiere permisos de superusuario." >&2
    exit 1
fi

# Función para manejar errores
mensaje_error() {
    if [ $? -ne 0 ]; then
        echo "ERROR: $1." >&2
        exit 1 # En caso de error termina la ejecución del script
    fi
}

# Actualizar repositorios y paquetes
echo "Actualizando repositorios..."
sudo apt update
mensaje_error "Falló la actualización de repositorios."

echo "Actualizando paquetes..."
sudo apt upgrade -y
mensaje_error "Falló la actualización de paquetes."


# Instalación de WP-CLI
# Descargar el archivo wp-cli.phar del repositorio oficial
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
mensaje_error "No se pudo descargar WP-CLI."

# Darle permisos de ejecución
chmod +x wp-cli.phar

# Mover archivo y cambiar nombre
sudo mv wp-cli.phar /usr/local/bin/wp

# Comprobar la instalación
wp --info > /dev/null 2>&1
mensaje_error "WP-CLI no se instaló correctamente."

# Preparar el directorio para WordPress
sudo rm -rf /var/www/html/*
mkdir -p /var/www/html
mensaje_error "No se pudo preparar el directorio para WordPress."

# Instalación de WordPress con WP-CLI
# Descargar codigo fuente
wp core download --locale=es_ES --path=/var/www/html --allow-root
mensaje_error "No se pudo descargar WordPress."

# Crear el archivo de configuración
wp config create --dbname="$DB_NAME" --dbuser="$DB_USER" --dbpass="$DB_PASSWORD" --dbhost=localhost --path=/var/www/html --allow-root
mensaje_error "No se pudo crear el archivo de configuración de WordPress."

# Ajustar permisos del archivo de configuración
sudo chmod 640 /var/www/html/wp-config.php
mensaje_error "No se pudieron ajustar los permisos del archivo wp-config.php."

# Instalación de WordPress
wp core install --url="$WP_URL" --title="$WP_TITLE" --admin_user="$WP_ADMIN_USER" --admin_password="$WP_ADMIN_PASSWORD" --admin_email="$WP_ADMIN_EMAIL" --path=/var/www/html --allow-root
mensaje_error "No se pudo instalar WordPress."

# Modificar el propietario y el grupo del directorio /var/www/html
sudo chown -R www-data:www-data /var/www/html
mensaje_error "No se pudieron ajustar los permisos del directorio de WordPress."

# Reiniciar Apache
sudo systemctl restart apache2
mensaje_error "No se pudo reiniciar Apache."

# Mensaje final
echo "¡WordPress instalado correctamente! Acceda a su sitio en http://$WP_URL"

# Fichero de control
touch /var/log/wp_installed.flag