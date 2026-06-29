import type { Metadata } from 'next';
import { LegalDoc } from '../_site/chrome';
import { privacyDoc } from '../_site/legal-data';

export const metadata: Metadata = {
  title: 'privacy policy — doubles',
  description: 'how doubles handles your data. an 18+ ai social sim by Pellar Technologies Limited.',
};

export default function PrivacyPage() {
  return <LegalDoc kicker="legal · privacy" updated="29 June 2026" data={privacyDoc} />;
}
