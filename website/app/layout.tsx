import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "4-7-8 Breathe — Calm Your Mind in Seconds",
  description:
    "Master the scientifically-backed 4-7-8 breathing technique with beautiful animations, haptic guidance, and HRV tracking on iPhone and Apple Watch.",
  openGraph: {
    title: "4-7-8 Breathe",
    description:
      "Calm your mind in seconds with the 4-7-8 breathing technique. Available on iPhone and Apple Watch.",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return children;
}
