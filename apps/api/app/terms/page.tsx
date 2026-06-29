import type { Metadata } from 'next';
import { LegalDoc } from '../_site/chrome';
import { termsDoc } from '../_site/legal-data';

export const metadata: Metadata = {
  title: 'terms of service — doubles',
  description: 'the rules for using doubles. an 18+ ai social sim by Pellar Technologies Limited.',
};

export default function TermsPage() {
  return <LegalDoc kicker="legal · terms" updated="29 June 2026" data={termsDoc} />;
}
