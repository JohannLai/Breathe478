import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "4-7-8 Breathe — Guided Mindful Breathing",
  description:
    "A gentle guide to 4-7-8 breathing with calming animations, haptic cues, and optional Apple Health insights on iPhone and Apple Watch.",
  openGraph: {
    title: "4-7-8 Breathe",
    description:
      "A gentle 4-7-8 breathing guide for iPhone and Apple Watch.",
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
