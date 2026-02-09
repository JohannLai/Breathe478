"use client";

import Image from "next/image";
import { useEffect, useRef, useState } from "react";

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
function Nav() {
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
          4-7-8 Breathe
        </span>
        <a
          href="#download"
          className="text-xs text-[var(--accent-teal)] hover:text-[var(--accent-blue)] transition-colors"
        >
          Download
        </a>
      </div>
    </nav>
  );
}

/* ─── Hero ─── */
function Hero() {
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

      {/* Breathing circle */}
      <div className="relative mb-12 animate-fade-in">
        <div className="animate-breathe">
          <div
            className="w-32 h-32 rounded-full"
            style={{
              background:
                "radial-gradient(circle, rgba(89,201,194,0.6) 0%, rgba(100,209,255,0.3) 50%, transparent 70%)",
              boxShadow: "0 0 80px rgba(89,201,194,0.3)",
            }}
          />
        </div>
      </div>

      {/* Headline */}
      <h1 className="text-5xl sm:text-7xl font-semibold tracking-tight leading-tight animate-fade-in-up">
        Breathe.
        <br />
        <span className="gradient-text">Feel calm.</span>
      </h1>

      <p className="mt-6 text-lg sm:text-xl text-[var(--text-secondary)] max-w-lg animate-fade-in-up delay-200">
        Master the scientifically-backed 4-7-8 breathing technique. Beautiful
        animations. Haptic guidance. HRV tracking.
      </p>

      <p className="mt-2 text-sm text-[var(--text-tertiary)] animate-fade-in-up delay-300">
        Available on iPhone and Apple Watch.
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
              Download on the
            </div>
            <div className="text-base font-medium leading-tight">App Store</div>
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
function TechniqueSection() {
  const phases = [
    {
      label: "Inhale",
      seconds: 4,
      color: "#59c9c2",
      description: "Breathe in quietly through your nose",
    },
    {
      label: "Hold",
      seconds: 7,
      color: "#4fb596",
      description: "Hold your breath gently",
    },
    {
      label: "Exhale",
      seconds: 8,
      color: "#64d1ff",
      description: "Exhale slowly through your mouth",
    },
  ];

  return (
    <section className="py-32 px-6">
      <div className="max-w-[980px] mx-auto">
        <RevealSection className="text-center mb-20">
          <p className="text-sm font-medium text-[var(--accent-teal)] tracking-widest uppercase mb-4">
            The Technique
          </p>
          <h2 className="text-4xl sm:text-5xl font-semibold tracking-tight">
            4-7-8.{" "}
            <span className="text-[var(--text-secondary)]">
              Three numbers that change everything.
            </span>
          </h2>
          <p className="mt-6 text-lg text-[var(--text-secondary)] max-w-2xl mx-auto">
            Developed by Dr. Andrew Weil, the 4-7-8 breathing technique is a
            natural tranquilizer for the nervous system. Four cycles is all it
            takes.
          </p>
        </RevealSection>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
          {phases.map((phase, i) => (
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
                  seconds
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
function IPhoneSection() {
  const features = [
    {
      title: "Stunning Visuals",
      desc: "A living, breathing flower animation guides your rhythm with fluid motion and color transitions.",
    },
    {
      title: "Haptic Guidance",
      desc: "Subtle vibrations mark each phase so you can close your eyes and simply feel the rhythm.",
    },
    {
      title: "Complete History",
      desc: "Track every session. View trends. Build a daily practice with streaks and insights.",
    },
  ];

  return (
    <section className="py-32 px-6 overflow-hidden">
      <div className="max-w-[1200px] mx-auto">
        <RevealSection className="text-center mb-20">
          <p className="text-sm font-medium text-[var(--accent-teal)] tracking-widest uppercase mb-4">
            iPhone
          </p>
          <h2 className="text-4xl sm:text-5xl font-semibold tracking-tight">
            Your calm companion.{" "}
            <span className="text-[var(--text-secondary)]">
              Always with you.
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
function WatchSection() {
  const labels = [
    "Practice anywhere",
    "Haptic coaching",
    "Session tracking",
    "HRV monitoring",
  ];

  return (
    <section className="py-32 px-6">
      <div className="max-w-[980px] mx-auto">
        <RevealSection className="text-center mb-20">
          <p className="text-sm font-medium text-[var(--accent-blue)] tracking-widest uppercase mb-4">
            Apple Watch
          </p>
          <h2 className="text-4xl sm:text-5xl font-semibold tracking-tight">
            On your wrist.{" "}
            <span className="text-[var(--text-secondary)]">In the moment.</span>
          </h2>
          <p className="mt-6 text-lg text-[var(--text-secondary)] max-w-2xl mx-auto">
            A fully independent watchOS app. Start a session right from your
            wrist with beautiful animations and precise haptic feedback.
          </p>
        </RevealSection>

        <RevealSection>
          <div className="flex gap-6 justify-center items-center mb-16 flex-wrap">
            {[1, 2, 3, 4].map((n, i) => (
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
function HealthSection() {
  const cards = [
    {
      icon: "♥",
      title: "Heart Rate Variability",
      desc: "Track your HRV before and after each session. See how breathing exercises improve your autonomic nervous system over time.",
      color: "#59c9c2",
    },
    {
      icon: "♡",
      title: "Heart Rate",
      desc: "Monitor real-time heart rate during sessions. Watch your body respond as you breathe with rhythm and intention.",
      color: "#4fb596",
    },
    {
      icon: "◎",
      title: "Mindful Minutes",
      desc: "Every session automatically saves to Apple Health as mindful minutes. Your practice counts toward your daily goals.",
      color: "#64d1ff",
    },
  ];

  return (
    <section className="py-32 px-6">
      <div className="max-w-[980px] mx-auto">
        <RevealSection className="text-center mb-20">
          <p className="text-sm font-medium text-[var(--accent-green)] tracking-widest uppercase mb-4">
            Health
          </p>
          <h2 className="text-4xl sm:text-5xl font-semibold tracking-tight">
            Science-backed insights.{" "}
            <span className="text-[var(--text-secondary)]">
              Powered by HealthKit.
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
function BenefitsSection() {
  const benefits = [
    {
      title: "Reduce Anxiety",
      desc: "Activate your parasympathetic nervous system in under 2 minutes.",
    },
    {
      title: "Sleep Better",
      desc: "Use as a pre-sleep routine to quiet racing thoughts.",
    },
    {
      title: "Lower Stress",
      desc: "Controlled breathing lowers cortisol levels naturally.",
    },
    {
      title: "Improve Focus",
      desc: "Reset your attention with a brief breathing break.",
    },
    {
      title: "Build Consistency",
      desc: "Streaks, history, and insights keep you motivated.",
    },
    {
      title: "Stay Private",
      desc: "All data stays on your device. No accounts. No tracking.",
    },
  ];

  return (
    <section className="py-32 px-6">
      <div className="max-w-[980px] mx-auto">
        <RevealSection className="text-center mb-20">
          <h2 className="text-4xl sm:text-5xl font-semibold tracking-tight">
            Why 4-7-8?
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
function PrivacySection() {
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
              Your privacy is everything.
            </h2>
            <p className="text-sm text-[var(--text-secondary)] leading-relaxed">
              4-7-8 Breathe processes everything on-device. No accounts. No
              cloud. No tracking. Your health data never leaves your iPhone or
              Apple Watch.
            </p>
          </div>
        </RevealSection>
      </div>
    </section>
  );
}

/* ─── CTA Section ─── */
function CTASection() {
  return (
    <section id="download" className="py-32 px-6">
      <div className="max-w-[600px] mx-auto text-center">
        <RevealSection>
          <h2 className="text-4xl sm:text-5xl font-semibold tracking-tight mb-6">
            Start breathing.
            <br />
            <span className="gradient-text">Start feeling.</span>
          </h2>
          <p className="text-lg text-[var(--text-secondary)] mb-10">
            Free to download. Available on iPhone and Apple Watch.
          </p>
          <a
            href="https://apps.apple.com/app/id6758927414"
            className="inline-flex items-center gap-3 px-8 py-4 rounded-full bg-white text-black font-medium hover:bg-white/90 transition-all duration-300"
          >
            <svg width="20" height="24" viewBox="0 0 17 20" fill="currentColor">
              <path d="M13.545 10.239c-.022-2.234 1.823-3.306 1.905-3.358-.037-.053-1.497-2.162-3.833-2.162-1.63 0-2.958.964-3.74.964-.807 0-2.023-.94-3.333-.914C2.37 4.797.5 6.277.5 9.94c0 2.208.847 4.534 1.905 6.04 1.042 1.474 1.948 2.805 3.39 2.752 1.356-.054 1.872-.87 3.516-.87 1.62 0 2.088.87 3.516.843 1.473-.027 2.26-1.382 3.275-2.87.554-.796.979-1.696 1.298-2.647-2.67-1.025-3.855-4.95-3.855-4.95z" />
              <path d="M11.173 3.267c.8-.993 1.348-2.353 1.195-3.767-1.155.053-2.575.795-3.4 1.767-.74.87-1.4 2.285-1.225 3.617 1.295.1 2.63-.66 3.43-1.617z" />
            </svg>
            Download on the App Store
          </a>
        </RevealSection>
      </div>
    </section>
  );
}

/* ─── Footer ─── */
function Footer() {
  return (
    <footer className="py-8 px-6 border-t border-white/[0.06]">
      <div className="max-w-[980px] mx-auto flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-[var(--text-tertiary)]">
        <span>
          &copy; {new Date().getFullYear()} 4-7-8 Breathe. All rights reserved.
        </span>
        <div className="flex gap-6">
          <a
            href="mailto:lizhihang.com@gmail.com"
            className="hover:text-[var(--foreground)] transition-colors"
          >
            Support
          </a>
          <a
            href="/privacy"
            className="hover:text-[var(--foreground)] transition-colors"
          >
            Privacy Policy
          </a>
        </div>
      </div>
    </footer>
  );
}

/* ─── Page ─── */
export default function Home() {
  return (
    <>
      <Nav />
      <main>
        <Hero />
        <div className="section-divider" />
        <TechniqueSection />
        <div className="section-divider" />
        <IPhoneSection />
        <div className="section-divider" />
        <WatchSection />
        <div className="section-divider" />
        <HealthSection />
        <div className="section-divider" />
        <BenefitsSection />
        <div className="section-divider" />
        <PrivacySection />
        <CTASection />
      </main>
      <Footer />
    </>
  );
}
