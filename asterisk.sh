#!/bin/sh

# Оголошення кольорів для виведення тексту
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Running as root...${NC}"
sleep 2
clear

# Оновлення списку доступних пакетів
opkg update

# Установка необхідних компонентів Asterisk
opkg install asterisk asterisk-pjsip asterisk-bridge-simple asterisk-codec-alaw asterisk-codec-ulaw asterisk-res-rtp-asterisk

# Видалення старого конфігураційного файлу extensions.conf і створення нового pjsip.conf
rm /etc/asterisk/extensions.conf
> /etc/asterisk/pjsip.conf

# Перехід до каталогу конфігурації Asterisk
cd /etc/asterisk/

# Завантаження файлу extensions.conf з репозиторію
wget https://raw.githubusercontent.com/Unicron33/diplome/refs/heads/main/extensions.conf

# Додавання транспортного протоколу до файлу pjsip.conf
echo "[simpletrans]
type=transport
protocol=udp
bind=0.0.0.0
" >> /etc/asterisk/pjsip.conf

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
    echo "Starting Asterisk..."
    service asterisk start
}
EOF

# Надаємо виконувані права новому стартовому скрипту
chmod +x /etc/init.d/asterisk_autorun

# Додаємо стартовий скрипт до автозапуску
/etc/init.d/asterisk_autorun enable

echo -e "${GREEN}Asterisk setup completed and added to startup.${NC}"
