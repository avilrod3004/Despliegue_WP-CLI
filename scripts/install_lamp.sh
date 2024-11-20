#!/bin/bash

# Cargar variables de entorno desde .env
if [ -f .env ]; then
    source .env
else
    echo "ERROR: No se ha encontrado el archivo .env" >&2
    exit 1
fi

# Validar que las variables están cargadas
if [[ -z "$DB_NAME" || -z "$DB_USER" || -z "$DB_PASSWORD" ]]; then
    echo "ERROR: Las variables DB_NAME, DB_USER o DB_PASSWORD no están definidas en .env" >&2
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


# LINUX
# Actualizar repositorios y paquetes
echo "Actualizando repositorios..."
sudo apt update
mensaje_error "Falló la actualización de repositorios."

echo "Actualizando paquetes..."
sudo apt upgrade -y
mensaje_error "Falló la actualización de paquetes."


# APACHE
# Instalación
echo "Instalando Apache..."
sudo apt install apache2 -y
mensaje_error "La instalación de Apache ha fallado."

# Iniciar apache
sudo systemctl enable apache2
sudo systemctl start apache2
mensaje_error "Falló al iniciar Apache."

# Comprobar si el servicio está corriendo
sudo systemctl status apache2 > /dev/null 2>&1 # Redirige la salida para que no se muestre
mensaje_error "Apache no está en ejecución"


# MySQL
# Instalación
sudo apt install mysql-server -y
mensaje_error "La instalación de MySQL ha fallado"

# Crear la base de datos
mysql -u root -e "CREATE DATABASE ${DB_NAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;" 2>&1
mensaje_error "No se pudo crear la base de datos ${DB_NAME}."

# Crear un usuario para acceder a la base de datos
mysql -u root -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';" 2>&1
mensaje_error "No se pudo crear el usuario ${DB_USER}."

# Darle permisos al usuario
mysql -u root -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';" 2>&1
mensaje_error "No se pudieron otorgar permisos al usuario ${DB_USER}."

# Aplicar los cambios
mysql -u root -e "FLUSH PRIVILEGES;" 2>&1
mensaje_error "No se pudieron aplicar los cambios de permisos."


# PHP
# Instalación
sudo apt install php libapache2-mod-php php-mysql -y
mensaje_error "La instalación de los paquetes de PHP ha fallado."

# Crear archivo de prueba
sudo cat > /var/www/html/info.php <<EOL
<?php
phpinfo();
?>
EOL

# Reiniciar Apache para aplicar los cambios
sudo systemctl restart apache2
mensaje_error "Falló al reiniciar Apache después de instalar PHP."

echo "¡LAMP instalado y configurado!"

# Fichero de control
touch /var/log/lamp_installed.flag
