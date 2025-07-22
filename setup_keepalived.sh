#!/bin/bash

# Если сервис Keepalived остановленны на обоих узлах, возможно нужно выпелить NetworkManager
# systemctl status NetworkManager

# Переменные
KEEPALIVED_CONF="/etc/keepalived/keepalived.conf"
VIRTUAL_IP="10.100.10.10"
INTERFACE="enp0s8"
PASSWORD="mE@3#6*V"
NODE_TYPE=$1  # Первый аргумент скрипта: MASTER или BACKUP

### Определение цветовых кодов ###
ESC=$(printf '\033') RESET="${ESC}[0m" MAGENTA="${ESC}[35m" RED="${ESC}[31m" GREEN="${ESC}[32m"

### Цветные функции ##
magentaprint() { echo; printf "${MAGENTA}%s${RESET}\n" "$1"; }
errorprint() { echo; printf "${RED}%s${RESET}\n" "$1"; }
greenprint() { echo; printf "${GREEN}%s${RESET}\n" "$1"; }


# ----------------------------------------------------------------------------------------------- #


# Проверка запуска через sudo
if [ -z "$SUDO_USER" ]; then
    errorprint "Пожалуйста, запустите скрипт через sudo."
    exit 1
fi


# Функция для установки и настройки Keepalived
setup_keepalived() {
    if [ "$NODE_TYPE" == "MASTER" ]; then
        PRIORITY=100
        STATE="MASTER"
        ROUTER_ID=LB-01
    elif [ "$NODE_TYPE" == "BACKUP" ]; then
        PRIORITY=99
        STATE="BACKUP"
        ROUTER_ID=LB-02
    else
        errorprint "Некорректный тип узла. Используйте 'MASTER' или 'BACKUP'."
        exit 1
    fi

    apt -y install keepalived
    
    cat <<EOF > $KEEPALIVED_CONF
global_defs {
  router_id $ROUTER_ID
  enable_script_security
  script_user root
}

vrrp_script check_haproxy {
  script \"/usr/bin/systemctl is-active --quiet haproxy\"
  interval 2
  weight -2
}

vrrp_instance VI_1 {
    state $STATE
    interface $INTERFACE
    virtual_router_id 51
    priority $PRIORITY
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass $PASSWORD
    }
    virtual_ipaddress {
        $VIRTUAL_IP
    }
    track_script {
        check_haproxy
    }
}
EOF

    magentaprint "Создание пользователя keepalived_script"
    useradd -s /usr/bin/nologin keepalived_script

    systemctl restart keepalived
    systemctl enable keepalived
    systemctl status keepalived

    greenprint "Установка Keepalived на узле $NODE_TYPE завершена и настроена!"
}


# Основной вызов функций
main() {
    setup_keepalived
}

