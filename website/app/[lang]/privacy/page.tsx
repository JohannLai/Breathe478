import type { Metadata } from "next";
import { getDictionary } from "../../../i18n/getDictionary";
import type { Locale } from "../../../i18n/config";

export const metadata: Metadata = {
  title: "Privacy Policy — 4-7-8 Breathe",
  description: "Privacy Policy for 4-7-8 Breathe app.",
};

export default async function PrivacyPolicy({
  params,
}: {
  params: Promise<{ lang: string }>;
}) {
  const { lang } = await params;
  const t = await getDictionary(lang as Locale);
  const p = t.privacyPage;

  return (
    <main
      className="min-h-screen px-6 py-20"
      style={{ background: "#000", color: "#f5f5f7" }}
    >
      <article className="max-w-[680px] mx-auto">
        <a
          href={`/${lang}`}
          className="text-sm text-[var(--accent-teal)] hover:text-[var(--accent-blue)] transition-colors"
        >
          &larr; {p.back}
        </a>

        <h1 className="text-4xl font-semibold tracking-tight mt-8 mb-2">
          {p.title}
        </h1>
        <p className="text-sm text-[var(--text-tertiary)] mb-12">
          {p.lastUpdated}
        </p>

        <div className="space-y-8 text-[15px] leading-relaxed text-[var(--text-secondary)]">
          <section>
            <h2 className="text-lg font-semibold text-[var(--foreground)] mb-3">
              {p.overviewTitle}
            </h2>
            <p>{p.overviewText}</p>
          </section>

          <section>
            <h2 className="text-lg font-semibold text-[var(--foreground)] mb-3">
              {p.dataCollectionTitle}
            </h2>
            <p dangerouslySetInnerHTML={{ __html: p.dataCollectionText }} />
            <ul className="list-disc list-inside mt-3 space-y-1.5">
              {p.dataCollectionItems.map((item: string) => (
                <li key={item}>{item}</li>
              ))}
            </ul>
          </section>

          <section>
            <h2 className="text-lg font-semibold text-[var(--foreground)] mb-3">
              {p.healthDataTitle}
            </h2>
            <p>{p.healthDataText}</p>
            <ul className="list-disc list-inside mt-3 space-y-1.5">
              {p.healthDataItems.map((item: string) => (
                <li key={item}>{item}</li>
              ))}
            </ul>
            <p className="mt-3">{p.healthDataFooter}</p>
          </section>

          <section>
            <h2 className="text-lg font-semibold text-[var(--foreground)] mb-3">
              {p.storageTitle}
            </h2>
            <p>{p.storageText}</p>
          </section>

          <section>
            <h2 className="text-lg font-semibold text-[var(--foreground)] mb-3">
              {p.networkTitle}
            </h2>
            <p>{p.networkText}</p>
          </section>

          <section>
            <h2 className="text-lg font-semibold text-[var(--foreground)] mb-3">
              {p.childrenTitle}
            </h2>
            <p>{p.childrenText}</p>
          </section>

          <section>
            <h2 className="text-lg font-semibold text-[var(--foreground)] mb-3">
              {p.changesTitle}
            </h2>
            <p>{p.changesText}</p>
          </section>

          <section>
            <h2 className="text-lg font-semibold text-[var(--foreground)] mb-3">
              {p.contactTitle}
            </h2>
            <p>
              {p.contactText}{" "}
              <a
                href="mailto:johannli666@gmail.com"
                className="text-[var(--accent-teal)] hover:text-[var(--accent-blue)] transition-colors"
              >
                johannli666@gmail.com
              </a>
              .
            </p>
          </section>
        </div>
      </article>
    </main>
  );
}
