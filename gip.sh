#!/bin/sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
 
clear
# Очищення екрану перед виведенням основного меню
echo -e "${YELLOW} SIP Server Manager ${NC}"
# Виведення заголовка меню

# Виведення пунктів меню
echo -e "${YELLOW} 1.${NC} ${CYAN} New SIP User ${NC}"
echo -e "${YELLOW} 2.${NC} ${CYAN} Delete SIP User ${NC}"
echo -e "${YELLOW} 3.${NC} ${CYAN} Show Users ${NC}"
echo -e "${YELLOW} 4.${NC} ${CYAN} Test Multiple SIP Calls ${NC}" # Новий пункт для тестування багатопоточних викликів
echo -e "${YELLOW} 5.${NC} ${RED} EXIT ${NC}"
echo ""

# Перевірка наявності резервної копії pjsip.conf
if [ ! -f /etc/asterisk/pjsip.conf ]; then
    echo -e "${CYAN}Restoring pjsip.conf from backup...${NC}"
    cp /root/pjsip.conf /etc/asterisk/pjsip.conf
fi

# Читання вибору користувача
read -p " -Enter option number: " choice

# Обробка вибору користувача
case $choice in
1)
    # Створення нового SIP користувача
    read -p " -Enter SIP User (4 digits number): " user
    read -p " -Enter SIP Password: " pass
    # Перевірка чи було введено 4 цифри
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
        gip
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
    read -p " -Enter SIP User to delete: " dele

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
    # Тестування багатопоточних SIP викликів
    echo -e "${CYAN} Starting SIPp Test with multiple simultaneous calls... ${NC}"
    read -p " -Enter number of simultaneous calls: " calls
    read -p " -Enter the SIP user (e.g., 1111): " user
    read -p " -Enter the SIP server IP: " ip

    echo -e "${CYAN} Running SIPp with $calls calls... ${NC}"
    sipp -sn uac -r $calls -s $user -p 5060 -i 192.168.5.2 $ip
    echo -e "${GREEN} Test completed! ${NC}"

    sleep 3
    gip
    ;;

5)  
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
