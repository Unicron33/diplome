#!/bin/sh
# Використання оболонки sh для виконання скрипта

RED='\033[0;31m'      # Визначення кольору для червоного тексту
GREEN='\033[0;32m'    # Визначення кольору для зеленого тексту
YELLOW='\033[1;33m'   # Визначення кольору для жовтого тексту
CYAN='\033[0;36m'     # Визначення кольору для блакитного тексту
NC='\033[0m'          # Скидання кольору (без кольору)

clear
# Очищення екрану перед виведенням основного меню

echo -e "${YELLOW} SIP Server Manager ${NC}"
# Виведення заголовка меню

# Виведення пунктів меню
echo -e "${YELLOW} 1.${NC} ${CYAN} New SIP User ${NC}"
echo -e "${YELLOW} 2.${NC} ${CYAN} Delete SIP User ${NC}"
echo -e "${YELLOW} 3.${NC} ${CYAN} Show Users ${NC}"
echo -e "${YELLOW} 4.${NC} ${RED} EXIT ${NC}"
echo ""

# Читання вибору користувача
read -p " -Enter option number: " choice

# Обробка вибору користувача
case $choice in
1)
    # Створення нового SIP користувача
    read -p " -Enter SIP User (4 digits number): " user  # Введення імені користувача
    read -p " -Enter SIP Password: " pass               # Введення пароля для користувача
    
    # Перевірка, чи введено 4 цифри
    if echo "$user" | grep -qE '^[0-9]{4}$'; then
        sleep 1
    else
        echo -e "${RED} ERROR: ${user} is not a 4-digit number! ${NC}"
        sleep 3
        gip # Повернення до основного меню
        exit 1
    fi

    # Перевірка, чи вже існує такий користувач
    USR=$(grep -o "aors = ${user}" /etc/asterisk/pjsip.conf | grep -o '[[:digit:]]*' | sed -n '1p')
    sleep 1

    if [ "$USR" == "$user" ]; then
        echo -e "${RED} ERROR: User ${user} already exists ${NC}"
        sleep 3
        gip # Повернення до основного меню
        exit 1
    else
        # Додавання нового користувача до файлу конфігурації Asterisk
        echo "[${user}] ;${user}
type = endpoint ;${user}
context = internal ;${user}
disallow = all ;${user}
allow = alaw ;${user}
aors = ${user} ;${user}
auth = auth${user} ;${user}
direct_media = no ;${user}

[${user}] ;${user}
type = aor ;${user}
max_contacts = 1 ;${user}
support_path = yes ;${user}

[auth${user}] ;${user}
type=auth ;${user}
auth_type=userpass ;${user}
password=${pass} ;${user}
username=${user} ;${user}
" >> /etc/asterisk/pjsip.conf
        
        echo -e "${GREEN} User ${user} Created Successfully ${NC}"
    fi

    # Перезапуск служби Asterisk для застосування змін
    service asterisk restart
    sleep 3
    gip
    ;;

2)
    # Видалення існуючого SIP користувача
    read -p " -Enter SIP User to delete: " dele  # Введення імені користувача

    # Перевірка, чи введено 4 цифри
    if echo "$dele" | grep -qE '^[0-9]{4}$'; then
        sleep 1
    else
        echo -e "${RED} ERROR: ${dele} is not a 4-digit number! ${NC}"
        sleep 3
        gip
        exit 1
    fi

    # Перевірка, чи існує такий користувач
    PUSR=$(grep -o "aors = ${dele}" /etc/asterisk/pjsip.conf | grep -o '[[:digit:]]*' | sed -n '1p')
    sleep 1

    if [ "$PUSR" == "$dele" ]; then
        # Видалення запису про користувача з конфігурації Asterisk
        sed -i "/;$dele/d" /etc/asterisk/pjsip.conf
        echo -e "${GREEN} User ${dele} Deleted Successfully ${NC}"
        service asterisk restart
    else
        echo -e "${RED} ERROR: User ${dele} does not exist ${NC}"
    fi
    sleep 3
    gip
    ;;

3)
    # Показ існуючих SIP користувачів
    asterisk -rx "pjsip list endpoints"
    sleep 3
    gip
    ;;

4)
    # Вихід з програми
    echo -e "${GREEN}Exiting...${NC}"
    exit 0
    ;;

*)
    # Обробка неправильного вибору
    echo -e "${RED} Invalid option! ${NC}"
    sleep 2
    gip
    ;;
esac
