#!/bin/bash

# Verificar que se ha ejecutado primero el script para instalar y configurar LAMP
if [ ! -f /var/log/lamp_installed.flag ]; then
    echo "ERROR: El entorno LAMP no está instalado. Ejecute primero el script "install_lamp.sh"." >&2
    exit 1
fi

if [ ! -f /var/log/wp_installed.flag ]; then
    echo "ERROR: Wordpress no está instalado. Ejecute primero el script "deploy_wordpress_with_wpcli.sh"." >&2
    exit 1
fi

# Cargar variables de entorno desde .env
if [ -f .env ]; then
    source .env
else
    echo "ERROR: No se ha encontrado el archivo .env" >&2
    exit 1
fi

# Validar que las variables están cargadas y es válida
if [[ -z "$WP_URL" ]]; then
    echo "ERROR: La variable WP_URL no está definida en .env." >&2
    exit 1
elif [[ ! "$WP_URL" =~ ^[a-zA-Z0-9.-]+$ ]]; then
    echo "ERROR: WP_URL no es un dominio válido." >&2
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


# Certbot
# Instalación
sudo apt install certbot python3-certbot-apache -y
mensaje_error "No se ha podido instalar Certbot o el módulo de Apache."

# Verificar que Certbot esté disponible
if ! command -v certbot &> /dev/null; then
    echo "ERROR: Certbot no está instalado correctamente." >&2
    exit 1
fi

# Solicitar certificado SSL/TLS con Certbot
sudo certbot --apache -d "$WP_URL"
mensaje_error "Falló la obtención del certificado SSL/TLS con Certbot."

# Verificar si Certbot configuró correctamente Apache
if ! sudo apache2ctl configtest > /dev/null 2>&1; then
    echo "ERROR: La configuración de Apache no es válida. Revise los archivos de configuración manualmente." >&2
    exit 1
fi

# Reiniciar Apache para aplicar los cambios
sudo systemctl restart apache2
mensaje_error "No se pudo reiniciar Apache después de la configuración del certificado SSL/TLS."

# Configurar renovación automática del certificado
sudo systemctl enable certbot.timer
mensaje_error "No se pudo habilitar la renovación automática del certificado SSL/TLS."

# Mensaje final
echo "¡Certificado SSL/TLS configurado correctamente para $WP_URL!"
echo "Acceda a su sitio web de forma segura en https://$WP_URL"
