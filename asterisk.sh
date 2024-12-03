#!/bin/sh

# Оголошення кольорів для виведення тексту
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Running as root...${NC}"
sleep 2
clear

# Оновлення списку доступних пакетів
opkg update

# Установка необхідних компонентів Asterisk
opkg install asterisk asterisk-pjsip asterisk-bridge-simple asterisk-codec-alaw asterisk-codec-ulaw asterisk-res-rtp-asterisk

# Перевірка, чи існує резервна копія pjsip.conf
if [ -f /root/pjsip.conf ]; then
    echo -e "${CYAN}Restoring pjsip.conf from backup...${NC}"
    cp /root/pjsip.conf /etc/asterisk/pjsip.conf
else
    echo -e "${CYAN}Creating new pjsip.conf...${NC}"
    > /etc/asterisk/pjsip.conf
    echo "[simpletrans]
type=transport
protocol=udp
bind=0.0.0.0
" >> /etc/asterisk/pjsip.conf

    # Зберігаємо резервну копію
    cp /etc/asterisk/pjsip.conf /root/pjsip.conf
fi

# Перехід до каталогу конфігурації Asterisk
cd /etc/asterisk/

# Завантаження файлу extensions.conf з репозиторію
wget -O extensions.conf https://raw.githubusercontent.com/Unicron33/diplome/refs/heads/main/extensions.conf

# Увімкнення Asterisk через систему налаштувань OpenWRT
uci set asterisk.general.enabled='1'

# Перезапуск служби Asterisk для застосування змін
service asterisk restart
sleep 1
service asterisk restart
sleep 1
service asterisk restart

# Завантаження та налаштування додаткового скрипта gip.sh
cd
rm -f gip.sh && wget https://raw.githubusercontent.com/Unicron33/diplome/refs/heads/main/gip.sh && chmod 777 gip.sh
cp gip.sh /sbin/gip

# Додавання Asterisk до автозапуску OpenWRT
echo -e "${CYAN}Adding Asterisk to startup...${NC}"
cat << 'EOF' > /etc/init.d/asterisk_autorun
#!/bin/sh /etc/rc.common
# Скрипт для автозапуску Asterisk
START=50

start() {
    echo "Ensuring /var/run/asterisk exists..."
    mkdir -p /var/run/asterisk
    chmod 755 /var/run/asterisk

    echo "Restoring pjsip.conf from backup..."
    cp /root/pjsip.conf /etc/asterisk/pjsip.conf

    echo "Waiting for system stabilization..."
    sleep 5

    echo "Starting Asterisk..."
    service asterisk start
}
EOF

# Надаємо виконувані права новому стартовому скрипту
chmod +x /etc/init.d/asterisk_autorun

# Додаємо стартовий скрипт до автозапуску
/etc/init.d/asterisk_autorun enable

echo -e "${GREEN}Asterisk setup completed and added to startup.${NC}"
