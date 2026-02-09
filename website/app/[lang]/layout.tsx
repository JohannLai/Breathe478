import { locales } from "../../i18n/config";
import { Analytics } from "@vercel/analytics/next";
import "../globals.css";

export async function generateStaticParams() {
  return locales.map((lang) => ({ lang }));
}

export default async function LangLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: Promise<{ lang: string }>;
}) {
  const { lang } = await params;
  return (
    <html lang={lang}>
      <body className="antialiased">
        {children}
        <Analytics />
      </body>
    </html>
  );
}
