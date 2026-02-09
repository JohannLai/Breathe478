import { getDictionary } from "../../i18n/getDictionary";
import type { Locale } from "../../i18n/config";
import HomeContent from "./HomeContent";

export default async function Home({
  params,
}: {
  params: Promise<{ lang: string }>;
}) {
  const { lang } = await params;
  const t = await getDictionary(lang as Locale);

  return <HomeContent t={t} lang={lang} />;
}
