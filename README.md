# Установка и настройка Keepalived на Almalinux

Скрипт автоматизирует установку и настройку Keepalived для организации отказоустойчивого виртуального IP на базе AlmaLinux.


## Использование

```bash
sudo ./setup_keepalived.sh MASTER
```
или
```bash
sudo ./setup_keepalived.sh BACKUP
```

## Аргументы

- `MASTER` — настройка узла как основного
- `BACKUP` — настройка узла как резервного

## Что делает скрипт

- Устанавливает пакет Keepalived
- Создаёт конфиг `/etc/keepalived/keepalived.conf` с параметрами VRRP
- Создаёт пользователя `keepalived_script`
- Перезапускает и включает службу Keepalived
- Показывает статус и версию Keepalived

## Переменные

Поменяйте заначения переменных на свои:
- **VIRTUAL_IP** - Виртуальный IP: `10.100.10.10`
- **INTERFACE** - Интерфейс: `eth0`
- **PASSWORD** - Пароль VRRP: `mE@3#6*V`

## Пример

```bash
sudo ./setup_keepalived.sh MASTER
```
