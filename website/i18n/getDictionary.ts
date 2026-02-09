import type { Locale } from "./config";

const dictionaries = {
  en: () => import("./dictionaries/en.json").then((m) => m.default),
  "zh-CN": () => import("./dictionaries/zh-CN.json").then((m) => m.default),
  "zh-TW": () => import("./dictionaries/zh-TW.json").then((m) => m.default),
};

export const getDictionary = async (locale: Locale) => {
  return dictionaries[locale]();
};

export type Dictionary = Awaited<ReturnType<typeof getDictionary>>;
