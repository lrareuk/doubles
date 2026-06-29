import type { CSSProperties } from 'react';

export const metadata = {
  title: 'you’re in — doubles',
  description: 'someone started a season on doubles. your seat is saved.',
};

const page: CSSProperties = {
  margin: 0,
  minHeight: '100vh',
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  background:
    'radial-gradient(120% 90% at 50% -10%, #2A0E1F 0%, #1B0B12 55%, #120710 100%)',
  color: '#F6EFE7',
  fontFamily:
    'ui-sans-serif, system-ui, -apple-system, "Segoe UI", Helvetica, Arial, sans-serif',
  padding: '32px 24px',
  boxSizing: 'border-box',
};

const panel: CSSProperties = {
  width: '100%',
  maxWidth: 460,
  textAlign: 'center',
};

const mark: CSSProperties = {
  fontWeight: 900,
  fontSize: 20,
  letterSpacing: '-0.04em',
  textTransform: 'lowercase',
  color: '#F6EFE7',
  marginBottom: 32,
};

const eyebrow: CSSProperties = {
  display: 'inline-block',
  fontSize: 13,
  fontWeight: 800,
  letterSpacing: '0.18em',
  textTransform: 'uppercase',
  color: '#E8FF59',
  marginBottom: 18,
};

const headline: CSSProperties = {
  margin: '0 0 14px',
  fontWeight: 900,
  letterSpacing: '-0.04em',
  lineHeight: 0.98,
  textTransform: 'lowercase',
  fontSize: 'clamp(40px, 11vw, 64px)',
  background: 'linear-gradient(180deg, #F6EFE7 0%, #FF2E74 130%)',
  WebkitBackgroundClip: 'text',
  backgroundClip: 'text',
  color: 'transparent',
};

const sub: CSSProperties = {
  margin: '0 0 28px',
  fontSize: 17,
  lineHeight: 1.45,
  color: 'rgba(246,239,231,0.7)',
};

const codeCard: CSSProperties = {
  border: '1px solid rgba(255,46,116,0.3)',
  background:
    'linear-gradient(180deg, rgba(255,46,116,0.1) 0%, rgba(42,14,31,0.55) 100%)',
  borderRadius: 18,
  padding: '20px 18px',
  marginBottom: 30,
};

const codeLabel: CSSProperties = {
  fontSize: 12,
  fontWeight: 800,
  letterSpacing: '0.22em',
  textTransform: 'uppercase',
  color: 'rgba(246,239,231,0.5)',
  marginBottom: 10,
};

const codeValue: CSSProperties = {
  fontFamily:
    'ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, monospace',
  fontSize: 'clamp(28px, 9vw, 40px)',
  fontWeight: 800,
  letterSpacing: '0.16em',
  color: '#E8FF59',
  wordBreak: 'break-all',
};

const ctaPrimary: CSSProperties = {
  display: 'block',
  background: '#FF2E74',
  color: '#1B0B12',
  fontWeight: 900,
  fontSize: 18,
  textDecoration: 'none',
  padding: '17px 24px',
  borderRadius: 14,
  boxShadow: '0 14px 40px rgba(255,46,116,0.4)',
  marginBottom: 14,
};

const ctaSecondary: CSSProperties = {
  display: 'block',
  color: '#F6EFE7',
  fontWeight: 700,
  fontSize: 16,
  textDecoration: 'none',
  padding: '15px 24px',
  borderRadius: 14,
  border: '1px solid rgba(246,239,231,0.22)',
};

const footnote: CSSProperties = {
  marginTop: 30,
  fontSize: 13,
  lineHeight: 1.55,
  color: 'rgba(246,239,231,0.42)',
};

export default async function JoinPage({
  params,
}: {
  params: Promise<{ code: string }>;
}) {
  const { code } = await params;
  const displayCode = decodeURIComponent(code).toUpperCase();
  const deepLink = `doubles://join?code=${encodeURIComponent(code)}`;

  return (
    <main style={page}>
      <div style={panel}>
        <div style={mark}>doubles</div>
        <span style={eyebrow}>you’ve been invited</span>
        <h1 style={headline}>you’re in.</h1>
        <p style={sub}>someone started a season. your seat is saved.</p>

        <div style={codeCard}>
          <div style={codeLabel}>your invite code</div>
          <div style={codeValue}>{displayCode}</div>
        </div>

        <a href={deepLink} style={ctaPrimary}>
          open in doubles
        </a>
        <a href="#" style={ctaSecondary}>
          don’t have it yet? get the app
        </a>

        <p style={footnote}>
          fictional ai characters, not real people · 18+ · the drama starts the
          second you walk in.
        </p>
      </div>
    </main>
  );
}
