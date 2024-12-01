#!/bin/sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
 
clear

echo -e "${YELLOW} SIP Server Manager ${NC}"
echo -e "${YELLOW} 1.${NC} ${CYAN} New SIP User ${NC}"
echo -e "${YELLOW} 2.${NC} ${CYAN} Delete SIP User ${NC}"
echo -e "${YELLOW} 3.${NC} ${CYAN} Show Users ${NC}"
echo -e "${YELLOW} 4.${NC} ${RED} EXIT ${NC}"
echo ""

read -p " -Enter option number: " choice

case $choice in
1)
    read -p " -Enter SIP User (4 digits number): " user
    read -p " -Enter SIP Password: " pass
    
    # Проверка, что пользователь ввёл 4 цифры
    if echo "$user" | grep -qE '^[0-9]{4}$'; then
        sleep 1
    else
        echo -e "${RED} ERROR: ${user} is not a 4-digit number! ${NC}"
        sleep 3
        /sbin/sip.sh
        exit 1
    fi

    USR=$(grep -o "aors = ${user}" /etc/asterisk/pjsip.conf | grep -o '[[:digit:]]*' | sed -n '1p')
    sleep 1

    if [ "$USR" == "$user" ]; then
        echo -e "${RED} ERROR: User ${user} already exists ${NC}"
        sleep 3
        /sbin/sip.sh
        exit 1
    else
        # Создание нового SIP-пользователя
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

    service asterisk restart
    sleep 3
    gip
    ;;

2)
    read -p " -Enter SIP User to delete: " dele

    # Проверка, что пользователь ввёл 4 цифры
    if echo "$dele" | grep -qE '^[0-9]{4}$'; then
        sleep 1
    else
        echo -e "${RED} ERROR: ${dele} is not a 4-digit number! ${NC}"
        sleep 3
        gip
        exit 1
    fi

    PUSR=$(grep -o "aors = ${dele}" /etc/asterisk/pjsip.conf | grep -o '[[:digit:]]*' | sed -n '1p')
    sleep 1

    if [ "$PUSR" == "$dele" ]; then
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
    asterisk -rx "pjsip list endpoints"
    sleep 3
    gip
    ;;

4)
    echo -e "${GREEN}Exiting...${NC}"
    exit 0
    ;;

*)
    echo -e "${RED} Invalid option! ${NC}"
    sleep 2
    gip
    ;;
esac
