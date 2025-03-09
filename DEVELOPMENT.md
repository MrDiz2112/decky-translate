# Инструкции по разработке и отладке плагина на Steam Deck

В этом документе описаны процессы разработки, сборки и отладки плагина для Steam Deck с использованием Decky Loader.

## Требования

- **Для разработки на Windows:**
  - PowerShell
  - [Node.js](https://nodejs.org/) и pnpm (`npm install -g pnpm`)
  - [7-Zip](https://www.7-zip.org/) (опционально, для лучшего сжатия)
  - [OpenSSH клиент](https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse) для Windows

- **Для разработки на Linux/macOS:**
  - Bash
  - [Node.js](https://nodejs.org/) и pnpm (`npm install -g pnpm`)
  - OpenSSH клиент (обычно уже установлен)
  - `zip` утилита

- **На Steam Deck:**
  - SteamOS с включенным SSH
  - Установленный [Decky Loader](https://github.com/SteamDeckHomebrew/decky-loader)
  - Включенный режим разработчика в Decky Loader

## Подготовка к разработке

### 1. Настройка SSH-доступа к Steam Deck

1. На Steam Deck:
   - Перейдите в режим Desktop Mode (Рабочий стол)
   - Откройте терминал и установите пароль: `passwd`
   - Включите SSH-сервер: `sudo systemctl enable --now sshd`
   - Узнайте IP-адрес Steam Deck: `ip addr show | grep 192`

2. На компьютере разработчика:
   - Проверьте подключение: `ssh deck@IP_АДРЕС_STEAM_DECK`

### 2. Сборка бинарных файлов Tesseract OCR

#### Для Windows (отладка):
```powershell
.\download_tesseract_win.ps1
```

#### Для SteamOS (на Linux/WSL):
```bash
chmod +x build_steamos.sh
./build_steamos.sh
```

## Процесс разработки и отладки

### Метод 1: Ручная установка через Decky Loader

Этот метод позволяет собрать плагин, отправить его на Steam Deck и установить через интерфейс Decky Loader. Это рекомендуемый способ для первоначальной проверки.

#### На Windows:
```powershell
.\build_and_send_to_deck.ps1 -DeckIP "IP_АДРЕС_STEAM_DECK"
```

#### На Linux/macOS:
```bash
chmod +x build_and_send_to_deck.sh
./build_and_send_to_deck.sh IP_АДРЕС_STEAM_DECK
```

Затем следуйте инструкциям на экране для установки плагина через интерфейс Decky Loader.

### Метод 2: Автоматическая установка для быстрой отладки

Этот метод позволяет автоматически обновлять уже установленный плагин, что ускоряет цикл разработки.

#### На Windows:
```powershell
.\deploy_to_deck.ps1 -DeckIP "IP_АДРЕС_STEAM_DECK"
```

#### На Linux/macOS:
```bash
chmod +x deploy_to_deck.sh
./deploy_to_deck.sh IP_АДРЕС_STEAM_DECK
```

### Просмотр логов

Для просмотра логов Decky Loader:
```bash
ssh deck@IP_АДРЕС_STEAM_DECK 'journalctl --user -u plugin_loader -f'
```

Для просмотра логов вашего плагина:
```bash
ssh deck@IP_АДРЕС_STEAM_DECK 'cat /home/deck/homebrew/plugins/decky-screenshot-ocr/tesseract_plugin.log'
```

## Продвинутая отладка (опционально)

Если вам требуется продвинутая отладка с возможностью ставить точки останова и отслеживать выполнение кода:

1. Настройка удаленной отладки:
```bash
chmod +x setup_remote_debug.sh
./setup_remote_debug.sh IP_АДРЕС_STEAM_DECK
```

2. Подключение через VSCode:
   - Откройте VSCode и используйте конфигурацию отладки "Attach to Steam Deck"
   - Обновите IP-адрес в файле `.vscode/launch.json`

## Распространенные проблемы и их решения

1. **Ошибка "SSH connection refused"**
   - Убедитесь, что SSH-сервер запущен на Steam Deck: `sudo systemctl status sshd`
   - Проверьте IP-адрес и доступность Steam Deck в сети

2. **Плагин не появляется в списке после установки**
   - Проверьте логи: `journalctl --user -u plugin_loader -f`
   - Убедитесь, что архив содержит все необходимые файлы
   - Проверьте, что имя плагина в package.json не конфликтует с существующими плагинами

3. **Ошибки при распознавании OCR**
   - Проверьте, что бинарные файлы Tesseract имеют правильные права доступа
   - Проверьте наличие языковых файлов в директории tessdata
   - Посмотрите логи плагина для более подробной информации