import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Privacy Policy — 4-7-8 Breathe",
  description: "Privacy Policy for 4-7-8 Breathe app.",
};

export default function PrivacyPolicy() {
  return (
    <main
      className="min-h-screen px-6 py-20"
      style={{ background: "#000", color: "#f5f5f7" }}
    >
      <article className="max-w-[680px] mx-auto">
        <a
          href="/"
          className="text-sm text-[var(--accent-teal)] hover:text-[var(--accent-blue)] transition-colors"
        >
          &larr; Back
        </a>

        <h1 className="text-4xl font-semibold tracking-tight mt-8 mb-2">
          Privacy Policy
        </h1>
        <p className="text-sm text-[var(--text-tertiary)] mb-12">
          Last updated: February 8, 2026
        </p>

        <div className="space-y-8 text-[15px] leading-relaxed text-[var(--text-secondary)]">
          <section>
            <h2 className="text-lg font-semibold text-[var(--foreground)] mb-3">
              Overview
            </h2>
            <p>
              4-7-8 Breathe (&quot;the App&quot;) is designed with your privacy
              as a top priority. We do not collect, store, or transmit any
              personal data. Everything stays on your device.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-semibold text-[var(--foreground)] mb-3">
              Data Collection
            </h2>
            <p>
              The App does{" "}
              <strong className="text-[var(--foreground)]">not</strong> collect
              any personal information. Specifically:
            </p>
            <ul className="list-disc list-inside mt-3 space-y-1.5">
              <li>No account creation or sign-in required</li>
              <li>No analytics or tracking SDKs</li>
              <li>No advertising identifiers</li>
              <li>No crash reporting to external servers</li>
              <li>No data shared with third parties</li>
            </ul>
          </section>

          <section>
            <h2 className="text-lg font-semibold text-[var(--foreground)] mb-3">
              Health Data
            </h2>
            <p>
              The App integrates with Apple HealthKit to read heart rate
              variability (HRV) and heart rate data, and to write mindful
              minutes. This data is:
            </p>
            <ul className="list-disc list-inside mt-3 space-y-1.5">
              <li>Accessed only with your explicit permission</li>
              <li>Processed entirely on your device</li>
              <li>Never transmitted to any server</li>
              <li>Never shared with any third party</li>
            </ul>
            <p className="mt-3">
              All health data is managed by Apple&apos;s HealthKit framework and
              subject to Apple&apos;s privacy policies.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-semibold text-[var(--foreground)] mb-3">
              On-Device Storage
            </h2>
            <p>
              Your breathing session history and preferences are stored locally
              on your iPhone and Apple Watch using SwiftData. This data is not
              accessible to us or any third party.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-semibold text-[var(--foreground)] mb-3">
              Network Usage
            </h2>
            <p>
              The App does not make any network requests. It works entirely
              offline.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-semibold text-[var(--foreground)] mb-3">
              Children&apos;s Privacy
            </h2>
            <p>
              The App does not collect any data from anyone, including children
              under the age of 13.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-semibold text-[var(--foreground)] mb-3">
              Changes to This Policy
            </h2>
            <p>
              We may update this Privacy Policy from time to time. Any changes
              will be reflected on this page with an updated revision date.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-semibold text-[var(--foreground)] mb-3">
              Contact
            </h2>
            <p>
              If you have any questions about this Privacy Policy, please
              contact us at{" "}
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
