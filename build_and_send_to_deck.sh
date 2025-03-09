#!/bin/bash

# Settings for Steam Deck connection
DECK_IP="${1:-192.168.1.100}"  # IP-адрес Steam Deck (можно передать первым аргументом)
DECK_USER="deck"               # Имя пользователя
REMOTE_PATH="/home/deck/Downloads"  # Путь на Steam Deck, куда сохранить архив

# Имя плагина (берётся из package.json)
PLUGIN_NAME=$(grep -m1 '"name":' package.json | cut -d'"' -f4)

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Сборка плагина для Decky Loader...${NC}"
# Убедимся, что у нас чистая сборка
if [ -d "dist" ]; then
    rm -rf dist
fi
pnpm run build || {
    echo -e "${RED}Ошибка сборки плагина!${NC}"
    exit 1
}

echo -e "${YELLOW}Создание структуры пакета плагина...${NC}"
TEMP_DIR="build_tmp"
if [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
fi

# Создаем правильную структуру плагина Decky
PLUGIN_DIR="$TEMP_DIR/$PLUGIN_NAME"
mkdir -p "$PLUGIN_DIR"

# Копируем необходимые файлы
echo -e "${YELLOW}Копирование файлов в пакет...${NC}"
cp -r dist "$PLUGIN_DIR/"

# Создаем директорию bin и копируем бинарные файлы Tesseract
if [ -d "bin/steamos" ]; then
    mkdir -p "$PLUGIN_DIR/bin"
    cp -r bin/steamos "$PLUGIN_DIR/bin/"
    echo -e "${GREEN}Бинарные файлы SteamOS скопированы в пакет${NC}"
else
    echo -e "${YELLOW}Предупреждение: бинарные файлы SteamOS не найдены. Убедитесь, что вы сначала их собрали.${NC}"
    echo -e "${YELLOW}Запустите ./build_steamos.sh для их сборки.${NC}"
fi

# Копируем другие необходимые файлы
cp plugin.json "$PLUGIN_DIR/"
cp package.json "$PLUGIN_DIR/"
cp main.py "$PLUGIN_DIR/"
cp LICENSE "$PLUGIN_DIR/"
[ -f requirements.txt ] && cp requirements.txt "$PLUGIN_DIR/"

# Проверяем наличие всех необходимых файлов
REQUIRED_FILES=("plugin.json" "package.json" "main.py" "LICENSE")
MISSING_FILES=false
for FILE in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$PLUGIN_DIR/$FILE" ]; then
        echo -e "${RED}Ошибка: необходимый файл $FILE отсутствует в пакете плагина!${NC}"
        MISSING_FILES=true
    fi
done
if [ "$MISSING_FILES" = true ]; then
    echo -e "${RED}Убедитесь, что все необходимые файлы присутствуют в вашем проекте${NC}"
    exit 1
fi

# Проверяем, есть ли содержимое в директории dist
if [ ! "$(ls -A "$PLUGIN_DIR/dist")" ]; then
    echo -e "${RED}Ошибка: директория dist пуста! Возможно, сборка не удалась.${NC}"
    exit 1
fi

echo -e "${YELLOW}Создание архива плагина...${NC}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
ARCHIVE_NAME="${PLUGIN_NAME}_${TIMESTAMP}.zip"

# Создание архива
CURRENT_DIR=$(pwd)
cd "$TEMP_DIR" || exit
zip -r "../$ARCHIVE_NAME" "$PLUGIN_NAME"
cd "$CURRENT_DIR" || exit

echo -e "${YELLOW}Копирование архива плагина на Steam Deck...${NC}"
# Копирование на Steam Deck через scp
scp "$ARCHIVE_NAME" "${DECK_USER}@${DECK_IP}:${REMOTE_PATH}/" || {
    echo -e "${RED}Ошибка копирования плагина на Steam Deck!${NC}"
    exit 1
}

echo -e "${YELLOW}Очистка временных файлов...${NC}"
rm -rf "$TEMP_DIR"

echo -e "${GREEN}Архив плагина успешно создан и отправлен на Steam Deck!${NC}"
echo -e "${GREEN}Расположение архива на Steam Deck: ${REMOTE_PATH}/${ARCHIVE_NAME}${NC}"
echo -e "${YELLOW}Инструкции по установке:${NC}"
echo -e "${CYAN}1. На вашем Steam Deck нажмите кнопку ... и откройте QAM (Quick Access Menu)${NC}"
echo -e "${CYAN}2. Найдите иконку Decky и откройте её${NC}"
echo -e "${CYAN}3. Откройте иконку шестеренки (настройки Decky)${NC}"
echo -e "${CYAN}4. Включите Режим разработчика, если он еще не включен${NC}"
echo -e "${CYAN}5. Выберите 'Установить плагин', а затем 'Из файла'${NC}"
echo -e "${CYAN}6. Перейдите в ${REMOTE_PATH} и выберите ${ARCHIVE_NAME}${NC}"
echo -e "${CYAN}7. Плагин должен установиться и появиться в списке плагинов${NC}"
echo -e ""
echo -e "${YELLOW}Чтобы проверить логи, если что-то пойдет не так:${NC}"
echo -e "${CYAN}  ssh ${DECK_USER}@${DECK_IP} 'journalctl --user -u plugin_loader -f'${NC}"