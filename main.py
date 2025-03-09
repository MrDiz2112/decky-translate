import os
import base64
from PIL import Image
import pytesseract
import mss
import numpy as np
import platform
import sys
import subprocess
import logging
from pathlib import Path
import requests
import json

# The decky plugin module is located at decky-loader/plugin
# For easy intellisense checkout the decky-loader code repo
# and add the `decky-loader/plugin/imports` path to `python.analysis.extraPaths` in `.vscode/settings.json`
import decky
import asyncio

# Настройка логирования
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("decky_translate.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("DeckyTranslate")

class Plugin:
    # Функция для перевода текста с использованием LibreTranslate API
    async def translate_text(self, text: str, source_lang: str, target_lang: str) -> str:
        try:
            if not text or text.strip() == "":
                logger.warning("Пустой текст для перевода")
                return "Текст для перевода не обнаружен"

            logger.info(f"Перевод текста с {source_lang} на {target_lang}")

            # Если языки совпадают, возвращаем исходный текст
            if source_lang == target_lang:
                logger.info("Языки совпадают, возвращаем исходный текст")
                return text

            # Используем бесплатный API LibreTranslate
            # Можно заменить на другой API перевода при необходимости
            api_url = "https://translate.argosopentech.com/translate"

            data = {
                "q": text,
                "source": source_lang,
                "target": target_lang,
                "format": "text"
            }

            headers = {
                "Content-Type": "application/json"
            }

            # Устанавливаем таймаут для запроса
            timeout = 8  # 8 секунд таймаут

            logger.info(f"Отправка запроса на перевод: {api_url}")
            response = requests.post(
                api_url,
                data=json.dumps(data),
                headers=headers,
                timeout=timeout
            )

            if response.status_code == 200:
                result = response.json()
                translated_text = result.get("translatedText", "")
                if not translated_text:
                    logger.warning("Получен пустой перевод")
                    return "Не удалось получить перевод"

                logger.info("Перевод успешно выполнен")
                return translated_text
            else:
                error_msg = f"Ошибка при переводе: {response.status_code} - {response.text}"
                logger.error(error_msg)
                return f"Ошибка перевода: {response.status_code}"

        except requests.Timeout:
            error_msg = "Превышено время ожидания при запросе перевода"
            logger.error(error_msg)
            return error_msg
        except requests.ConnectionError:
            error_msg = "Ошибка соединения при запросе перевода"
            logger.error(error_msg)
            return error_msg
        except Exception as e:
            error_msg = f"Ошибка при переводе: {str(e)}"
            logger.error(error_msg)
            return error_msg

    # Asyncio-compatible long-running code, executed in a task when the plugin is loaded
    async def _main(self):
        logger.info("Инициализация плагина Decky Translate")
        # Определяем путь к бинарным файлам Tesseract в зависимости от платформы
        self.plugin_dir = os.path.dirname(os.path.realpath(__file__))

        if platform.system() == "Windows":
            self.tesseract_wrapper = os.path.join(self.plugin_dir, "bin", "windows", "run_tesseract.bat")
            self.tesseract_path = os.path.join(self.plugin_dir, "bin", "windows", "tesseract.exe")
            self.tessdata_path = os.path.join(self.plugin_dir, "bin", "windows", "tessdata")
        else:  # SteamOS/Linux
            self.tesseract_wrapper = os.path.join(self.plugin_dir, "bin", "steamos", "bin", "run_tesseract.sh")
            self.tesseract_path = os.path.join(self.plugin_dir, "bin", "steamos", "bin", "tesseract")
            self.tessdata_path = os.path.join(self.plugin_dir, "bin", "steamos", "tessdata")

        # Установка переменной окружения для tessdata
        os.environ["TESSDATA_PREFIX"] = self.tessdata_path
        logger.info(f"TESSDATA_PREFIX установлен на {self.tessdata_path}")

        # Проверяем, существует ли скрипт-оболочка
        if os.path.exists(self.tesseract_wrapper):
            logger.info(f"Найден скрипт-оболочка для Tesseract: {self.tesseract_wrapper}")
            # Используем оболочку для Tesseract
            self.use_wrapper = True
        elif os.path.exists(self.tesseract_path):
            logger.info(f"Найден бинарный файл Tesseract: {self.tesseract_path}")
            pytesseract.pytesseract.tesseract_cmd = self.tesseract_path
            self.use_wrapper = False
        else:
            # Если бинарный файл не найден, пытаемся использовать системный tesseract
            logger.warning(f"Tesseract binary не найден. Попытка использовать системный tesseract")
            self.use_wrapper = False

        # Проверка наличия языковых данных
        if not os.path.exists(os.path.join(self.tessdata_path, "eng.traineddata")):
            logger.warning("Файл языковых данных eng.traineddata не найден!")

        logger.info("Инициализация плагина завершена")

    # Function called first during the unload process, utilize this to handle your plugin being stopped, but not
    # completely removed
    async def _unload(self):
        logger.info("Выгрузка плагина")
        pass

    # Function called after `_unload` during uninstall, utilize this to clean up processes and other remnants of your
    # plugin that may remain on the system
    async def _uninstall(self):
        logger.info("Удаление плагина")
        pass

    # Migrations that should be performed before entering `_main()`.
    async def _migration(self):
        logger.info("Миграция")
        # Here's a migration example for logs:
        # - `~/.config/decky-template/template.log` will be migrated to `decky.decky_LOG_DIR/template.log`
        decky.migrate_logs(os.path.join(decky.DECKY_USER_HOME,
                                               ".config", "decky-translate", "translate.log"))
        # Here's a migration example for settings:
        # - `~/homebrew/settings/template.json` is migrated to `decky.decky_SETTINGS_DIR/template.json`
        # - `~/.config/decky-template/` all files and directories under this root are migrated to `decky.decky_SETTINGS_DIR/`
        decky.migrate_settings(
            os.path.join(decky.DECKY_HOME, "settings", "translate.json"),
            os.path.join(decky.DECKY_USER_HOME, ".config", "decky-translate"))
        # Here's a migration example for runtime data:
        # - `~/homebrew/template/` all files and directories under this root are migrated to `decky.decky_RUNTIME_DIR/`
        # - `~/.local/share/decky-template/` all files and directories under this root are migrated to `decky.decky_RUNTIME_DIR/`
        decky.migrate_runtime(
            os.path.join(decky.DECKY_HOME, "translate"),
            os.path.join(decky.DECKY_USER_HOME, ".local", "share", "decky-translate"))

    async def perform_ocr(self, image_path):
        """Выполняет OCR с помощью Tesseract, используя оболочку или прямой вызов."""
        try:
            if self.use_wrapper:
                # Используем оболочку через subprocess
                logger.info(f"Выполнение OCR через wrapper: {self.tesseract_wrapper}")
                cmd = [self.tesseract_wrapper, image_path, 'stdout']
                logger.debug(f"Выполняемая команда: {' '.join(cmd)}")

                result = subprocess.run(
                    cmd,
                    capture_output=True,
                    text=True,
                    check=True
                )
                return result.stdout.strip()
            else:
                # Используем pytesseract
                logger.info(f"Выполнение OCR через pytesseract")
                return pytesseract.image_to_string(Image.open(image_path))
        except Exception as e:
            logger.error(f"OCR Error: {str(e)}")
            return f"OCR Error: {str(e)}"

    async def take_screenshot(self):
        try:
            logger.info("Создание скриншота")
            with mss.mss() as sct:
                monitor = sct.monitors[0]  # Capture primary monitor
                screenshot = sct.grab(monitor)
                if not screenshot:
                    logger.error("Не удалось создать скриншот")
                    return {
                        "success": False,
                        "error": "Не удалось создать скриншот"
                    }

                img = Image.frombytes('RGB', screenshot.size, screenshot.rgb)

                # Save to temporary file
                temp_path = os.path.join(self.plugin_dir, "temp_screenshot.png")
                img.save(temp_path)
                logger.info(f"Скриншот сохранен в {temp_path}")

                # Convert to base64 for frontend
                try:
                    with open(temp_path, "rb") as image_file:
                        encoded_string = base64.b64encode(image_file.read()).decode()
                except Exception as e:
                    logger.error(f"Ошибка при кодировании изображения: {str(e)}")
                    return {
                        "success": False,
                        "error": f"Ошибка при кодировании изображения: {str(e)}"
                    }

                # Perform OCR
                logger.info("Начало распознавания текста")
                text = await self.perform_ocr(temp_path)
                if not text or text.strip() == "":
                    logger.warning("Текст не распознан")
                    text = "Текст не распознан. Попробуйте сделать другой скриншот."

                logger.info("Распознавание текста завершено")

                return {
                    "success": True,
                    "image": encoded_string,
                    "text": text
                }
        except Exception as e:
            logger.error(f"Screenshot Error: {str(e)}")
            return {
                "success": False,
                "error": str(e)
            }

    # Define method that will be called from the frontend
    async def get_screenshot_with_ocr(self):
        logger.info("Получен запрос на создание скриншота с OCR")
        try:
            result = await self.take_screenshot()
            return result
        except Exception as e:
            logger.error(f"Общая ошибка при создании скриншота с OCR: {str(e)}")
            return {
                "success": False,
                "error": f"Ошибка: {str(e)}"
            }
