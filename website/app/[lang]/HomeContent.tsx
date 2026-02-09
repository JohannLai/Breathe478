"use client";

import Image from "next/image";
import { useEffect, useRef, useState } from "react";
import type { Dictionary } from "../../i18n/getDictionary";

/* ─── Scroll Reveal Hook ─── */
function useReveal() {
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          el.classList.add("visible");
          observer.unobserve(el);
        }
      },
      { threshold: 0.15 },
    );
    observer.observe(el);
    return () => observer.disconnect();
  }, []);
  return ref;
}

function RevealSection({
  children,
  className = "",
}: {
  children: React.ReactNode;
  className?: string;
}) {
  const ref = useReveal();
  return (
    <div ref={ref} className={`reveal ${className}`}>
      {children}
    </div>
  );
}

/* ─── Nav ─── */
function Nav({ t, lang }: { t: Dictionary; lang: string }) {
  const [scrolled, setScrolled] = useState(false);
  useEffect(() => {
    const handler = () => setScrolled(window.scrollY > 20);
    window.addEventListener("scroll", handler, { passive: true });
    return () => window.removeEventListener("scroll", handler);
  }, []);

  return (
    <nav
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
        scrolled ? "nav-blur border-b border-white/[0.08]" : "bg-transparent"
      }`}
    >
      <div className="max-w-[980px] mx-auto px-6 h-12 flex items-center justify-between">
        <span className="text-sm font-medium text-[var(--foreground)] tracking-tight">
          {t.nav.title}
        </span>
        <div className="flex items-center gap-4">
          <LanguageSwitcher lang={lang} />
          <a
            href="#download"
            className="text-xs text-[var(--accent-teal)] hover:text-[var(--accent-blue)] transition-colors"
          >
            {t.nav.download}
          </a>
        </div>
      </div>
    </nav>
  );
}

/* ─── Language Switcher ─── */
function LanguageSwitcher({ lang }: { lang: string }) {
  const languages = [
    { code: "en", label: "EN" },
    { code: "zh-CN", label: "简" },
    { code: "zh-TW", label: "繁" },
  ];

  return (
    <div className="flex items-center gap-1 text-xs">
      {languages.map((l, i) => (
        <span key={l.code} className="flex items-center gap-1">
          {i > 0 && <span className="text-[var(--text-tertiary)]">/</span>}
          {l.code === lang ? (
            <span className="text-[var(--foreground)] font-medium">{l.label}</span>
          ) : (
            <a
              href={`/${l.code}`}
              className="text-[var(--text-tertiary)] hover:text-[var(--foreground)] transition-colors"
            >
              {l.label}
            </a>
          )}
        </span>
      ))}
    </div>
  );
}

/* ─── Hero ─── */
function Hero({ t }: { t: Dictionary }) {
  return (
    <section className="relative min-h-screen flex flex-col items-center justify-center text-center px-6 overflow-hidden">
      {/* Background glow */}
      <div
        className="glow-circle"
        style={{
          width: 600,
          height: 600,
          background:
            "radial-gradient(circle, rgba(89,201,194,0.12) 0%, transparent 70%)",
          top: "10%",
          left: "50%",
          transform: "translateX(-50%)",
        }}
      />

      {/* Breathing flower — 6 petals matching iOS PetalView */}
      <div className="relative mb-12 animate-fade-in" style={{ width: 240, height: 240 }}>
        {/* Glow behind flower */}
        <div
          className="absolute inset-0 rounded-full animate-breathe"
          style={{
            background: "radial-gradient(circle, rgba(89,201,194,0.25) 0%, transparent 70%)",
            filter: "blur(20px)",
          }}
        />
        <div
          className="relative w-full h-full"
          style={{ animation: "flowerRotate 60s linear infinite" }}
        >
          {[0, 60, 120, 180, 240, 300].map((deg) => (
            <div
              key={deg}
              className="absolute inset-0 flex items-center justify-center"
              style={{ transform: `rotate(${deg}deg)` }}
            >
              <div
                className="rounded-full"
                style={{
                  width: 100,
                  height: 100,
                  position: "relative",
                  left: 0,
                  backgroundColor: "rgba(89, 201, 194, 0.7)",
                  mixBlendMode: "plus-lighter",
                  animation: "petalBreath 19s cubic-bezier(0.42,0,0.58,1) infinite",
                }}
              />
            </div>
          ))}
        </div>
      </div>

      {/* Headline */}
      <h1 className="text-5xl sm:text-7xl font-semibold tracking-tight leading-tight animate-fade-in-up">
        {t.hero.headline1}
        <br />
        <span className="gradient-text">{t.hero.headline2}</span>
      </h1>

      <p className="mt-6 text-lg sm:text-xl text-[var(--text-secondary)] max-w-lg animate-fade-in-up delay-200">
        {t.hero.subtitle}
      </p>

      <p className="mt-2 text-sm text-[var(--text-tertiary)] animate-fade-in-up delay-300">
        {t.hero.platforms}
      </p>

      {/* App Store badge */}
      <div className="mt-10 animate-fade-in-up delay-400">
        <a
          href="https://apps.apple.com/app/id6758927414"
          className="inline-flex items-center gap-3 px-8 py-4 rounded-full border border-white/[0.15] hover:border-white/[0.3] bg-white/[0.04] hover:bg-white/[0.08] transition-all duration-300"
        >
          <svg width="20" height="24" viewBox="0 0 17 20" fill="currentColor">
            <path d="M13.545 10.239c-.022-2.234 1.823-3.306 1.905-3.358-.037-.053-1.497-2.162-3.833-2.162-1.63 0-2.958.964-3.74.964-.807 0-2.023-.94-3.333-.914C2.37 4.797.5 6.277.5 9.94c0 2.208.847 4.534 1.905 6.04 1.042 1.474 1.948 2.805 3.39 2.752 1.356-.054 1.872-.87 3.516-.87 1.62 0 2.088.87 3.516.843 1.473-.027 2.26-1.382 3.275-2.87.554-.796.979-1.696 1.298-2.647-2.67-1.025-3.855-4.95-3.855-4.95z" />
            <path d="M11.173 3.267c.8-.993 1.348-2.353 1.195-3.767-1.155.053-2.575.795-3.4 1.767-.74.87-1.4 2.285-1.225 3.617 1.295.1 2.63-.66 3.43-1.617z" />
          </svg>
          <div className="text-left">
            <div className="text-[10px] text-[var(--text-secondary)] leading-none">
              {t.hero.downloadOn}
            </div>
            <div className="text-base font-medium leading-tight">{t.hero.appStore}</div>
          </div>
        </a>
      </div>

      {/* Scroll indicator */}
      <div className="absolute bottom-10 animate-fade-in delay-800">
        <div className="w-6 h-10 rounded-full border-2 border-white/20 flex justify-center pt-2">
          <div
            className="w-1 h-2 rounded-full bg-white/40"
            style={{
              animation: "floatUp 2s ease-in-out infinite",
            }}
          />
        </div>
      </div>
    </section>
  );
}

/* ─── Technique Section ─── */
function TechniqueSection({ t }: { t: Dictionary }) {
  const phases = [
    {
      label: t.technique.inhale,
      seconds: 4,
      color: "#59c9c2",
      description: t.technique.inhaleDesc,
    },
    {
      label: t.technique.hold,
      seconds: 7,
      color: "#4fb596",
      description: t.technique.holdDesc,
    },
    {
      label: t.technique.exhale,
      seconds: 8,
      color: "#64d1ff",
      description: t.technique.exhaleDesc,
    },
  ];

  return (
    <section className="py-32 px-6">
      <div className="max-w-[980px] mx-auto">
        <RevealSection className="text-center mb-20">
          <p className="text-sm font-medium text-[var(--accent-teal)] tracking-widest uppercase mb-4">
            {t.technique.label}
          </p>
          <h2 className="text-4xl sm:text-5xl font-semibold tracking-tight">
            {t.technique.title1}{" "}
            <span className="text-[var(--text-secondary)]">
              {t.technique.title2}
            </span>
          </h2>
          <p className="mt-6 text-lg text-[var(--text-secondary)] max-w-2xl mx-auto">
            {t.technique.description}
          </p>
        </RevealSection>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
          {phases.map((phase) => (
            <RevealSection key={phase.label}>
              <div
                className="rounded-2xl p-8 text-center"
                style={{
                  background: "var(--card-bg)",
                  border: "1px solid var(--card-border)",
                }}
              >
                <div
                  className="text-6xl font-light mb-4"
                  style={{ color: phase.color }}
                >
                  {phase.seconds}
                </div>
                <div className="text-xs tracking-widest uppercase text-[var(--text-secondary)] mb-2">
                  {t.technique.seconds}
                </div>
                <h3 className="text-xl font-semibold mb-2">{phase.label}</h3>
                <p className="text-sm text-[var(--text-tertiary)]">
                  {phase.description}
                </p>
              </div>
            </RevealSection>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ─── iPhone Section ─── */
function IPhoneSection({ t }: { t: Dictionary }) {
  const features = [
    { title: t.iphone.feature1Title, desc: t.iphone.feature1Desc },
    { title: t.iphone.feature2Title, desc: t.iphone.feature2Desc },
    { title: t.iphone.feature3Title, desc: t.iphone.feature3Desc },
  ];

  return (
    <section className="py-32 px-6 overflow-hidden">
      <div className="max-w-[1200px] mx-auto">
        <RevealSection className="text-center mb-20">
          <p className="text-sm font-medium text-[var(--accent-teal)] tracking-widest uppercase mb-4">
            {t.iphone.label}
          </p>
          <h2 className="text-4xl sm:text-5xl font-semibold tracking-tight">
            {t.iphone.title1}{" "}
            <span className="text-[var(--text-secondary)]">
              {t.iphone.title2}
            </span>
          </h2>
        </RevealSection>

        {/* Phone screenshots */}
        <RevealSection>
          <div className="flex gap-6 justify-center items-end mb-20 flex-wrap">
            {[1, 2, 3, 4].map((n, i) => (
              <div
                key={n}
                className="phone-frame w-[200px] sm:w-[240px] flex-shrink-0"
                style={{
                  animationDelay: `${i * 0.15}s`,
                }}
              >
                <Image
                  src={`/screenshots/iphone/screen${n}.png`}
                  alt={`iPhone screenshot ${n}`}
                  width={240}
                  height={520}
                  className="w-full h-auto"
                />
              </div>
            ))}
          </div>
        </RevealSection>

        {/* Features */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-8 max-w-[980px] mx-auto">
          {features.map((f) => (
            <RevealSection key={f.title}>
              <div className="text-center">
                <h3 className="text-lg font-semibold mb-2">{f.title}</h3>
                <p className="text-sm text-[var(--text-secondary)] leading-relaxed">
                  {f.desc}
                </p>
              </div>
            </RevealSection>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ─── Watch Section ─── */
function WatchSection({ t }: { t: Dictionary }) {
  const labels = [t.watch.tag1, t.watch.tag2, t.watch.tag3, t.watch.tag4];

  return (
    <section className="py-32 px-6">
      <div className="max-w-[980px] mx-auto">
        <RevealSection className="text-center mb-20">
          <p className="text-sm font-medium text-[var(--accent-blue)] tracking-widest uppercase mb-4">
            {t.watch.label}
          </p>
          <h2 className="text-4xl sm:text-5xl font-semibold tracking-tight">
            {t.watch.title1}{" "}
            <span className="text-[var(--text-secondary)]">{t.watch.title2}</span>
          </h2>
          <p className="mt-6 text-lg text-[var(--text-secondary)] max-w-2xl mx-auto">
            {t.watch.description}
          </p>
        </RevealSection>

        <RevealSection>
          <div className="flex gap-6 justify-center items-center mb-16 flex-wrap">
            {[1, 2, 3, 4].map((n) => (
              <div
                key={n}
                className="watch-frame w-[140px] sm:w-[170px] flex-shrink-0"
              >
                <Image
                  src={`/screenshots/watch/watch${n}.png`}
                  alt={`Apple Watch screenshot ${n}`}
                  width={170}
                  height={210}
                  className="w-full h-auto"
                />
              </div>
            ))}
          </div>
        </RevealSection>

        <RevealSection>
          <div className="flex flex-wrap gap-4 justify-center">
            {labels.map((label) => (
              <span
                key={label}
                className="px-5 py-2 rounded-full text-sm text-[var(--text-secondary)]"
                style={{
                  background: "var(--card-bg)",
                  border: "1px solid var(--card-border)",
                }}
              >
                {label}
              </span>
            ))}
          </div>
        </RevealSection>
      </div>
    </section>
  );
}

/* ─── Health Section ─── */
function HealthSection({ t }: { t: Dictionary }) {
  const cards = [
    {
      icon: "♥",
      title: t.health.card1Title,
      desc: t.health.card1Desc,
      color: "#59c9c2",
    },
    {
      icon: "♡",
      title: t.health.card2Title,
      desc: t.health.card2Desc,
      color: "#4fb596",
    },
    {
      icon: "◎",
      title: t.health.card3Title,
      desc: t.health.card3Desc,
      color: "#64d1ff",
    },
  ];

  return (
    <section className="py-32 px-6">
      <div className="max-w-[980px] mx-auto">
        <RevealSection className="text-center mb-20">
          <p className="text-sm font-medium text-[var(--accent-green)] tracking-widest uppercase mb-4">
            {t.health.label}
          </p>
          <h2 className="text-4xl sm:text-5xl font-semibold tracking-tight">
            {t.health.title1}{" "}
            <span className="text-[var(--text-secondary)]">
              {t.health.title2}
            </span>
          </h2>
        </RevealSection>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
          {cards.map((card) => (
            <RevealSection key={card.title}>
              <div
                className="rounded-2xl p-8 h-full"
                style={{
                  background: "var(--card-bg)",
                  border: "1px solid var(--card-border)",
                }}
              >
                <div className="text-3xl mb-4" style={{ color: card.color }}>
                  {card.icon}
                </div>
                <h3 className="text-lg font-semibold mb-3">{card.title}</h3>
                <p className="text-sm text-[var(--text-secondary)] leading-relaxed">
                  {card.desc}
                </p>
              </div>
            </RevealSection>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ─── Benefits Section ─── */
function BenefitsSection({ t }: { t: Dictionary }) {
  const benefits = [
    { title: t.benefits.b1Title, desc: t.benefits.b1Desc },
    { title: t.benefits.b2Title, desc: t.benefits.b2Desc },
    { title: t.benefits.b3Title, desc: t.benefits.b3Desc },
    { title: t.benefits.b4Title, desc: t.benefits.b4Desc },
    { title: t.benefits.b5Title, desc: t.benefits.b5Desc },
    { title: t.benefits.b6Title, desc: t.benefits.b6Desc },
  ];

  return (
    <section className="py-32 px-6">
      <div className="max-w-[980px] mx-auto">
        <RevealSection className="text-center mb-20">
          <h2 className="text-4xl sm:text-5xl font-semibold tracking-tight">
            {t.benefits.title}
          </h2>
        </RevealSection>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-8">
          {benefits.map((b) => (
            <RevealSection key={b.title}>
              <div>
                <h3 className="text-lg font-semibold mb-2">{b.title}</h3>
                <p className="text-sm text-[var(--text-secondary)] leading-relaxed">
                  {b.desc}
                </p>
              </div>
            </RevealSection>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ─── Privacy Section ─── */
function PrivacySection({ t }: { t: Dictionary }) {
  return (
    <section className="py-32 px-6">
      <div className="max-w-[600px] mx-auto text-center">
        <RevealSection>
          <div
            className="rounded-3xl p-12"
            style={{
              background: "var(--card-bg)",
              border: "1px solid var(--card-border)",
            }}
          >
            <div className="text-4xl mb-6">🔒</div>
            <h2 className="text-2xl font-semibold mb-4">
              {t.privacy.sectionTitle}
            </h2>
            <p className="text-sm text-[var(--text-secondary)] leading-relaxed">
              {t.privacy.sectionDesc}
            </p>
          </div>
        </RevealSection>
      </div>
    </section>
  );
}

/* ─── CTA Section ─── */
function CTASection({ t }: { t: Dictionary }) {
  return (
    <section id="download" className="py-32 px-6">
      <div className="max-w-[600px] mx-auto text-center">
        <RevealSection>
          <h2 className="text-4xl sm:text-5xl font-semibold tracking-tight mb-6">
            {t.cta.title1}
            <br />
            <span className="gradient-text">{t.cta.title2}</span>
          </h2>
          <p className="text-lg text-[var(--text-secondary)] mb-10">
            {t.cta.subtitle}
          </p>
          <a
            href="https://apps.apple.com/app/id6758927414"
            className="inline-flex items-center gap-3 px-8 py-4 rounded-full bg-white text-black font-medium hover:bg-white/90 transition-all duration-300"
          >
            <svg width="20" height="24" viewBox="0 0 17 20" fill="currentColor">
              <path d="M13.545 10.239c-.022-2.234 1.823-3.306 1.905-3.358-.037-.053-1.497-2.162-3.833-2.162-1.63 0-2.958.964-3.74.964-.807 0-2.023-.94-3.333-.914C2.37 4.797.5 6.277.5 9.94c0 2.208.847 4.534 1.905 6.04 1.042 1.474 1.948 2.805 3.39 2.752 1.356-.054 1.872-.87 3.516-.87 1.62 0 2.088.87 3.516.843 1.473-.027 2.26-1.382 3.275-2.87.554-.796.979-1.696 1.298-2.647-2.67-1.025-3.855-4.95-3.855-4.95z" />
              <path d="M11.173 3.267c.8-.993 1.348-2.353 1.195-3.767-1.155.053-2.575.795-3.4 1.767-.74.87-1.4 2.285-1.225 3.617 1.295.1 2.63-.66 3.43-1.617z" />
            </svg>
            {t.cta.button}
          </a>
        </RevealSection>
      </div>
    </section>
  );
}

/* ─── Footer ─── */
function Footer({ t, lang }: { t: Dictionary; lang: string }) {
  return (
    <footer className="py-8 px-6 border-t border-white/[0.06]">
      <div className="max-w-[980px] mx-auto flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-[var(--text-tertiary)]">
        <span>
          &copy; {new Date().getFullYear()} {t.footer.copyright}
        </span>
        <div className="flex gap-6">
          <a
            href="mailto:lizhihang.com@gmail.com"
            className="hover:text-[var(--foreground)] transition-colors"
          >
            {t.footer.support}
          </a>
          <a
            href={`/${lang}/privacy`}
            className="hover:text-[var(--foreground)] transition-colors"
          >
            {t.footer.privacyPolicy}
          </a>
        </div>
      </div>
    </footer>
  );
}

/* ─── Page Content (Client Component) ─── */
export default function HomeContent({ t, lang }: { t: Dictionary; lang: string }) {
  return (
    <>
      <Nav t={t} lang={lang} />
      <main>
        <Hero t={t} />
        <div className="section-divider" />
        <TechniqueSection t={t} />
        <div className="section-divider" />
        <IPhoneSection t={t} />
        <div className="section-divider" />
        <WatchSection t={t} />
        <div className="section-divider" />
        <HealthSection t={t} />
        <div className="section-divider" />
        <BenefitsSection t={t} />
        <div className="section-divider" />
        <PrivacySection t={t} />
        <CTASection t={t} />
      </main>
      <Footer t={t} lang={lang} />
    </>
  );
}
