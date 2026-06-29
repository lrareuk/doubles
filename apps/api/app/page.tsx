import type { Metadata } from 'next';
import type { CSSProperties } from 'react';
import { SiteHeader, SiteFooter } from './_site/chrome';
import { marketing as m } from './_site/marketing-data';

export const metadata: Metadata = {
  title: m.metaTitle,
  description: m.metaDescription,
};

// App Store link — placeholder until the app is live on the store.
const APP_LINK = '#get';

const wrap: CSSProperties = { width: '100%', maxWidth: 'var(--maxw)', margin: '0 auto', padding: '0 var(--pad)' };
const wordmark: CSSProperties = {
  margin: '26px 0 0', fontFamily: 'var(--font-display)', fontWeight: 400, lineHeight: 0.84,
  textTransform: 'uppercase', fontSize: 'clamp(88px, 21vw, 260px)', letterSpacing: '0.01em',
  background: 'linear-gradient(180deg, var(--bone) 0%, var(--magenta) 125%)',
  WebkitBackgroundClip: 'text', backgroundClip: 'text', color: 'transparent',
  textShadow: '0 0 90px rgba(255,46,116,0.22)',
};
const hook: CSSProperties = {
  marginTop: 18, maxWidth: 760, fontSize: 'clamp(26px, 4.6vw, 44px)', lineHeight: 1.08,
  fontWeight: 800, letterSpacing: '-0.025em',
};
const subhook: CSSProperties = { marginTop: 22, maxWidth: 600, fontSize: 18, lineHeight: 1.5, color: 'var(--bone-dim)' };
const ctaRow: CSSProperties = { marginTop: 36, display: 'flex', flexWrap: 'wrap', gap: 14, alignItems: 'center' };

const sectionLabel: CSSProperties = {
  fontFamily: 'var(--font-mono)', fontSize: 13, fontWeight: 700, letterSpacing: '0.2em',
  textTransform: 'uppercase', color: 'var(--rose)', marginBottom: 22,
};
const grid = (min: number): CSSProperties => ({ display: 'grid', gridTemplateColumns: `repeat(auto-fit, minmax(${min}px, 1fr))`, gap: 16 });
const card: CSSProperties = { background: 'var(--surface)', border: '1px solid var(--line)', padding: '26px 24px' };
const cardTitle: CSSProperties = { margin: '0 0 10px', fontFamily: 'var(--font-display)', fontWeight: 400, fontSize: 26, textTransform: 'uppercase', letterSpacing: '0.01em' };
const cardBody: CSSProperties = { margin: 0, fontSize: 15.5, lineHeight: 1.55, color: 'var(--bone-dim)' };
const kicker: CSSProperties = { fontFamily: 'var(--font-mono)', fontSize: 12, fontWeight: 700, letterSpacing: '0.18em', textTransform: 'uppercase', color: 'var(--acid)', marginBottom: 14 };

export default function Home() {
  return (
    <main>
      <SiteHeader />

      {/* hero */}
      <section style={{ ...wrap, paddingTop: 48, paddingBottom: 56 }}>
        <h1 style={wordmark} className="rise">doubles</h1>
        <p style={hook} className="rise">
          {m.hero.hookLead} <span style={{ color: 'var(--magenta)' }}>{m.hero.hookAccent}</span>
        </p>
        <p style={subhook} className="rise">{m.hero.subhook}</p>
        <div style={ctaRow} className="rise">
          <a href={APP_LINK} className="btn btn--primary">{m.hero.primaryCta}</a>
          <a href="#how" className="btn btn--ghost">{m.hero.secondaryCta}</a>
        </div>
      </section>

      {/* how it goes down */}
      <section id="how" style={{ ...wrap, paddingTop: 40, paddingBottom: 24 }}>
        <p style={sectionLabel}>how it goes down</p>
        <div style={grid(260)}>
          {m.steps.map((s) => (
            <div key={s.num} style={card}>
              <div style={{ fontFamily: 'var(--font-display)', fontSize: 56, lineHeight: 1, color: 'var(--magenta)', marginBottom: 12 }}>{s.num}</div>
              <h2 style={cardTitle}>{s.title}</h2>
              <p style={cardBody}>{s.body}</p>
            </div>
          ))}
        </div>
      </section>

      {/* features */}
      <section style={{ ...wrap, paddingTop: 56, paddingBottom: 24 }}>
        <p style={sectionLabel}>what you're signing up for</p>
        <div style={grid(280)}>
          {m.features.map((f, i) => (
            <div key={i} style={{ ...card, background: i % 2 === 0 ? 'var(--surface)' : 'var(--surface-lift)' }}>
              <div style={kicker}>{f.kicker}</div>
              <h3 style={{ ...cardTitle, fontSize: 22 }}>{f.title}</h3>
              <p style={cardBody}>{f.body}</p>
            </div>
          ))}
        </div>
      </section>

      {/* a night in the life — sample feed */}
      <section style={{ ...wrap, paddingTop: 56, paddingBottom: 24 }}>
        <p style={sectionLabel}>a night in the life</p>
        <div style={{ display: 'grid', gap: 12, maxWidth: 720 }}>
          {m.sampleFeed.map((b, i) => (
            <div key={i} style={{ ...card, borderLeft: `3px solid ${i % 2 === 0 ? 'var(--magenta)' : 'var(--acid)'}`, padding: '18px 20px' }}>
              <div style={{ fontFamily: 'var(--font-mono)', fontSize: 12, fontWeight: 700, letterSpacing: '0.08em', color: i % 2 === 0 ? 'var(--magenta)' : 'var(--acid)', marginBottom: 7 }}>
                @{b.handle}<span style={{ color: 'var(--bone-dim)', fontWeight: 400 }}>&nbsp;&nbsp;· 3:14am</span>
              </div>
              <p style={{ margin: 0, fontSize: 16, lineHeight: 1.5 }}>{b.text}</p>
            </div>
          ))}
        </div>
        <p style={{ marginTop: 16, fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: '0.06em', color: 'rgba(246,239,231,0.4)', textTransform: 'uppercase' }}>
          dramatised. every character is ai fiction.
        </p>
      </section>

      {/* faq */}
      <section id="faq" style={{ ...wrap, paddingTop: 56, paddingBottom: 24 }}>
        <p style={sectionLabel}>the obvious questions</p>
        <div style={{ display: 'grid', gap: 0, maxWidth: 760 }}>
          {m.faq.map((item, i) => (
            <div key={i} style={{ padding: '22px 0', borderTop: '1px solid var(--line)' }}>
              <h3 style={{ margin: '0 0 8px', fontSize: 18, fontWeight: 800, letterSpacing: '-0.01em' }}>{item.q}</h3>
              <p style={{ margin: 0, fontSize: 16, lineHeight: 1.55, color: 'var(--bone-dim)' }}>{item.a}</p>
            </div>
          ))}
        </div>
      </section>

      {/* 18+ honesty strip */}
      <section style={{ ...wrap, paddingTop: 40 }}>
        <div style={{ border: '1px solid rgba(232,255,89,0.3)', background: 'rgba(232,255,89,0.05)', padding: '20px 22px', display: 'flex', gap: 16, alignItems: 'flex-start' }}>
          <span style={{ flex: '0 0 auto', fontFamily: 'var(--font-mono)', fontWeight: 700, fontSize: 14, color: 'var(--ink)', background: 'var(--acid)', padding: '4px 9px' }}>18+</span>
          <p style={{ margin: 0, fontSize: 15, lineHeight: 1.5, color: 'rgba(246,239,231,0.85)' }}>
            adults only. the doubles are ai fiction — not real people, and nobody here speaks for anyone real. don't use it to depict real people without their say-so. you bring the friends, we bring the chaos. keep it consenting, keep it grown.
          </p>
        </div>
      </section>

      {/* closer */}
      <section id="get" style={{ ...wrap, paddingTop: 80, paddingBottom: 72, textAlign: 'center' }}>
        <p style={{ margin: '0 auto 28px', maxWidth: 720, fontFamily: 'var(--font-display)', fontWeight: 400, fontSize: 'clamp(40px, 8vw, 88px)', lineHeight: 0.92, textTransform: 'uppercase' }}>
          {m.closerLine}
        </p>
        <a href={APP_LINK} className="btn btn--primary" style={{ fontSize: 16, padding: '18px 34px' }}>{m.hero.primaryCta}</a>
      </section>

      <SiteFooter />
    </main>
  );
}
