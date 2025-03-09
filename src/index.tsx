import {
  ButtonItem,
  PanelSection,
  PanelSectionRow,
  Navigation,
  staticClasses,
  TextField,
  Focusable,
  showModal,
  ModalRoot,
  DialogButton,
  Field,
  ToggleField
} from "@decky/ui";
import {
  addEventListener,
  removeEventListener,
  callable,
  definePlugin,
  toaster,
  // routerHook
} from "@decky/api"
import { useState, useEffect, FC } from "react";
import { FaLanguage } from "react-icons/fa";

// import logo from "../assets/logo.png";

// This function calls the python function "add", which takes in two numbers and returns their sum (as a number)
// Note the type annotations:
//  the first one: [first: number, second: number] is for the arguments
//  the second one: number is for the return value
const add = callable<[first: number, second: number], number>("add");

// This function calls the python function "start_timer", which takes in no arguments and returns nothing.
// It starts a (python) timer which eventually emits the event 'timer_event'
const startTimer = callable<[], void>("start_timer");

// Функция для вызова OCR и получения текста с экрана
const captureScreenAndOcr = callable<[], any>("get_screenshot_with_ocr");

// Функция для перевода текста
const translateText = callable<[text: string, sourceLang: string, targetLang: string], string>("translate_text");

// Доступные языки для перевода
const languageOptions = [
  { id: "en", label: "English" },
  { id: "ru", label: "Русский" },
  { id: "de", label: "Deutsch" },
  { id: "fr", label: "Français" },
  { id: "es", label: "Español" },
  { id: "it", label: "Italiano" },
  { id: "ja", label: "日本語" },
  { id: "ko", label: "한국어" },
  { id: "zh", label: "中文" }
];

// Компонент выбора языка
const LanguageSelector: FC<{
  label: string,
  selectedLanguage: string,
  onSelect: (langId: string) => void
}> = ({ label, selectedLanguage, onSelect }) => {
  const [showOptions, setShowOptions] = useState<boolean>(false);

  const selectedLang = languageOptions.find(lang => lang.id === selectedLanguage) || languageOptions[0];

  return (
    <Focusable style={{ display: "flex", flexDirection: "column", width: "100%" }}>
      <Field label={label}>
        <ButtonItem
          onClick={() => setShowOptions(!showOptions)}
        >
          {selectedLang.label}
        </ButtonItem>
      </Field>

      {showOptions && (
        <Focusable style={{
          display: "flex",
          flexDirection: "column",
          marginTop: "8px",
          padding: "8px",
          background: "rgba(0, 0, 0, 0.2)",
          borderRadius: "4px"
        }}>
          {languageOptions.map(lang => (
            <ButtonItem
              key={lang.id}
              onClick={() => {
                onSelect(lang.id);
                setShowOptions(false);
              }}
              style={{
                background: lang.id === selectedLanguage ? "rgba(255, 255, 255, 0.1)" : "transparent",
                margin: "2px 0"
              }}
            >
              {lang.label}
            </ButtonItem>
          ))}
        </Focusable>
      )}
    </Focusable>
  );
};

// Упрощенное модальное окно для отображения текста Hello World
const SimpleModal: FC<{
  closeModal: () => void
}> = ({ closeModal }) => {
  return (
    <ModalRoot onCancel={closeModal}>
      <Focusable style={{ display: "flex", flexDirection: "column", padding: "16px" }}>
        <div style={{
          fontSize: "24px",
          fontWeight: "bold",
          textAlign: "center",
          margin: "20px 0",
          color: "#ffffff"
        }}>
          Hello World
        </div>

        <div style={{ display: "flex", justifyContent: "flex-end", marginTop: "16px" }}>
          <DialogButton onClick={closeModal}>Закрыть</DialogButton>
        </div>
      </Focusable>
    </ModalRoot>
  );
};

function Content() {
  const [sourceLang, setSourceLang] = useState<string>("en");
  const [targetLang, setTargetLang] = useState<string>("ru");
  const [isLoading, setIsLoading] = useState<boolean>(false);

  const handleCapture = async () => {
    // Просто показываем оверлей с текстом Hello World
    showModal(
      <SimpleModal closeModal={() => Navigation.closeModal()} />
    );
  };

  return (
    <PanelSection title="Decky Translate">
      <PanelSectionRow>
        <LanguageSelector
          label="Язык оригинала"
          selectedLanguage={sourceLang}
          onSelect={setSourceLang}
        />
      </PanelSectionRow>

      <PanelSectionRow>
        <LanguageSelector
          label="Язык перевода"
          selectedLanguage={targetLang}
          onSelect={setTargetLang}
        />
      </PanelSectionRow>

      <PanelSectionRow>
        <ButtonItem
          layout="below"
          onClick={handleCapture}
        >
          {"Сделать скриншот и перевести"}
        </ButtonItem>
      </PanelSectionRow>
    </PanelSection>
  );
};

export default definePlugin(() => {
  console.log("Decky Translate plugin initializing");

  // serverApi.routerHook.addRoute("/decky-plugin-test", DeckyPluginRouterTest, {
  //   exact: true,
  // });

  // Add an event listener to the "timer_event" event from the backend
  const listener = addEventListener<[
    test1: string,
    test2: boolean,
    test3: number
  ]>("timer_event", (test1: string, test2: boolean, test3: number) => {
    console.log("Template got timer_event with:", test1, test2, test3)
    toaster.toast({
      title: "template got timer_event",
      body: `${test1}, ${test2}, ${test3}`
    });
  });

  return {
    // The name shown in various decky menus
    name: "Decky Translate",
    // The element displayed at the top of your plugin's menu
    titleView: <div className={staticClasses.Title}>Decky Translate</div>,
    // The content of your plugin's menu
    content: <Content />,
    // The icon displayed in the plugin list
    icon: <FaLanguage />,
    // The function triggered when your plugin unloads
    onDismount() {
      console.log("Decky Translate plugin unloading");
      removeEventListener("timer_event", listener);
      // serverApi.routerHook.removeRoute("/decky-plugin-test");
    },
  };
});
