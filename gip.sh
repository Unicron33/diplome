#!/bin/sh

# Визначення кольорів для виведення
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Перевірка наявності сокета Asterisk
if [ ! -e /var/run/asterisk/asterisk.ctl ]; then
    echo -e "${YELLOW}Asterisk socket not found. Starting Asterisk...${NC}"
    service asterisk start
    sleep 2  # Затримка для впевненості, що служба запустилася
fi

# Перевірка, чи Asterisk працює
if pgrep -x "asterisk" > /dev/null; then
    echo -e "${GREEN}Asterisk is running.${NC}"
else
    echo -e "${RED}Failed to start Asterisk. Please check the logs.${NC}"
    exit 1
fi

# Меню для управління SIP користувачами
clear
echo -e "${CYAN} SIP Server Manager ${NC}"
echo -e "${YELLOW} 1.${NC} ${CYAN} New SIP User ${NC}"
echo -e "${YELLOW} 2.${NC} ${CYAN} Delete SIP User ${NC}"
echo -e "${YELLOW} 3.${NC} ${CYAN} Show Users ${NC}"
echo -e "${YELLOW} 4.${NC} ${RED} EXIT ${NC}"
echo ""

read -p " -Enter option number: " choice

case $choice in
1)
    # Додавання нового SIP користувача
    read -p " -Enter SIP User (4 digits number): " user
    read -p " -Enter SIP Password: " pass

    if echo "$user" | grep -qE '^[0-9]{4}$'; then
        sleep 1
    else
        echo -e "${RED} ERROR: ${user} is not a 4-digit number! ${NC}"
        exit 1
    fi

    USR=$(grep -o "aors = ${user}" /etc/asterisk/pjsip.conf | grep -o '[[:digit:]]*' | sed -n '1p')

    if [ "$USR" == "$user" ]; then
        echo -e "${RED} ERROR: User ${user} already exists ${NC}"
    else
        echo "[${user}]
type = endpoint
context = internal
disallow = all
allow = alaw
aors = ${user}
auth = auth${user}
direct_media = no

[auth${user}]
type = auth
auth_type = userpass
username = ${user}
password = ${pass}

[${user}]
type = aor
max_contacts = 1
" >> /etc/asterisk/pjsip.conf
        echo -e "${GREEN} User ${user} Created Successfully ${NC}"
        service asterisk restart
    fi
    ;;
2)
    # Видалення SIP користувача
    read -p " -Enter SIP User to delete: " dele
    if echo "$dele" | grep -qE '^[0-9]{4}$'; then
        PUSR=$(grep -o "aors = ${dele}" /etc/asterisk/pjsip.conf | grep -o '[[:digit:]]*' | sed -n '1p')

        if [ "$PUSR" == "$dele" ]; then
            sed -i "/aors = ${dele}/d" /etc/asterisk/pjsip.conf
            echo -e "${GREEN} User ${dele} Deleted Successfully ${NC}"
            service asterisk restart
        else
            echo -e "${RED} ERROR: User ${dele} does not exist ${NC}"
        fi
    else
        echo -e "${RED} ERROR: ${dele} is not a 4-digit number! ${NC}"
    fi
    ;;
3)
    # Показ існуючих користувачів
    asterisk -rx "pjsip list endpoints"
    ;;
4)
    # Вихід з програми
    echo -e "${GREEN}Exiting...${NC}"
    exit 0
    ;;
*)
    # Некоректний вибір
    echo -e "${RED} Invalid option! ${NC}"
    ;;
esac
