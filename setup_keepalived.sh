#!/bin/bash

# Переменные
KEEPALIVED_CONF="/etc/keepalived/keepalived.conf"   # Путь к конфигурационному файлу Keepalived
VIRTUAL_IP="10.100.10.10/24"                        # Виртуальный IP-адрес
INTERFACE="eth0"                                    # Сетевой интерфейс для VRRP
PASSWORD="mE@3#6*V"                                 # Пароль для аутентификации VRRP
NODE_TYPE=$1                                        # Первый аргумент скрипта: MASTER или BACKUP
OS=$(awk -F= '/^ID=/{gsub(/"/, "", $2); print $2}' /etc/os-release) # Переменная определения и хранения дистрибутива

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

# Проверка заданных аргументов
if [ "$NODE_TYPE" == "MASTER" ]; then
    PRIORITY=100
    STATE="MASTER"
    ROUTER_ID=LB-01
elif [ "$NODE_TYPE" == "BACKUP" ]; then
    PRIORITY=99
    STATE="BACKUP"
    ROUTER_ID=LB-02
else
    errorprint "Некорректный тип узла. Используйте аргумент 'MASTER' или 'BACKUP'."
    magentaprint "Пример: $0 MASTER"
    exit 1
fi

ubuntu() {
    magentaprint "Установка keepalived ..."
    apt -y install keepalived 
}

almalinux() {
    magentaprint "Установка keepalived ..."
    dnf -y install keepalived    
}

# Выбор ОС для установки keepalived:
check_os() {
  if [ "$OS" == "ubuntu" ]; then
      ubuntu
  elif [ "$OS" == "almalinux" ]; then
      almalinux
  else
      errorprint "Скрипт не поддерживает установленную ОС: $OS"
      exit 1
  fi
}

# Функция для установки и настройки Keepalived
setup_keepalived() {  
    magentaprint "Настройка конфигурационного файл Keepalived $KEEPALIVED_CONF"
    cat <<EOF > $KEEPALIVED_CONF
global_defs {
  router_id $ROUTER_ID
  enable_script_security
  script_user keepalived_script
}

vrrp_script check_haproxy {
  script "/usr/bin/systemctl is-active --quiet haproxy"
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

    magentaprint "Проверка статуса Keepalived:"
    systemctl restart keepalived                # Перезапуск службы для применения изменений
    systemctl enable --now keepalived
    systemctl status keepalived --no-pager

    magentaprint "Версия Keepalived:"
    keepalived --version

    greenprint "Установка Keepalived на узле $NODE_TYPE завершена и настроена!"
}


main() {
    check_os
    setup_keepalived
}

# Вызов основной функции
main