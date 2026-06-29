// Shared site chrome: header, footer, chyron, and the long-form legal renderer.
// Server components — no client JS needed.
import Link from 'next/link';

const CONTACT = 'alex@lrare.co.uk';

export function SiteHeader() {
  return (
    <header className="wrap" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '24px var(--pad)' }}>
      <Link href="/" style={{ textDecoration: 'none' }}>
        <span style={{ fontFamily: 'var(--font-display)', fontSize: 22, letterSpacing: '0.02em', textTransform: 'uppercase' }}>doubles</span>
      </Link>
      <nav style={{ display: 'flex', alignItems: 'center', gap: 22, fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: '0.12em', textTransform: 'uppercase' }}>
        <Link href="/#how" style={{ textDecoration: 'none', color: 'var(--bone-dim)' }}>how</Link>
        <Link href="/#faq" style={{ textDecoration: 'none', color: 'var(--bone-dim)' }} className="hide-sm">faq</Link>
        <Link href="/#get" className="btn btn--primary" style={{ padding: '10px 16px' }}>get the app</Link>
      </nav>
    </header>
  );
}

export function SiteFooter() {
  const col: React.CSSProperties = { display: 'flex', flexDirection: 'column', gap: 10, fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: '0.1em', textTransform: 'uppercase' };
  const link: React.CSSProperties = { textDecoration: 'none', color: 'var(--bone-dim)' };
  return (
    <footer style={{ borderTop: '1px solid var(--line)', marginTop: 80 }}>
      <div className="wrap" style={{ padding: '48px var(--pad)', display: 'flex', flexWrap: 'wrap', gap: 40, justifyContent: 'space-between' }}>
        <div style={{ maxWidth: 320 }}>
          <div style={{ fontFamily: 'var(--font-display)', fontSize: 30, textTransform: 'uppercase' }}>doubles</div>
          <p style={{ marginTop: 10, fontSize: 14, color: 'var(--bone-dim)', lineHeight: 1.5 }}>
            your friends. but ai. living their own lives while you sleep.
          </p>
        </div>
        <div style={col}>
          <span style={{ color: 'var(--rose)' }}>the app</span>
          <Link href="/#how" style={link}>how it works</Link>
          <Link href="/#faq" style={link}>faq</Link>
          <Link href="/#get" style={link}>get the app</Link>
        </div>
        <div style={col}>
          <span style={{ color: 'var(--rose)' }}>legal</span>
          <Link href="/privacy" style={link}>privacy policy</Link>
          <Link href="/terms" style={link}>terms of service</Link>
          <a href={`mailto:${CONTACT}`} style={link}>contact</a>
        </div>
      </div>
      <div className="wrap" style={{ padding: '0 var(--pad) 48px' }}>
        <p style={{ fontFamily: 'var(--font-mono)', fontSize: 11, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'rgba(246,239,231,0.4)', lineHeight: 1.7 }}>
          fictional ai characters · not real people · 18+ · © {new Date().getFullYear()} Pellar Technologies Limited
        </p>
      </div>
    </footer>
  );
}

export function Chyron({ tag, value, acid = false }: { tag: string; value: string; acid?: boolean }) {
  return (
    <div className={`chyron${acid ? ' chyron--acid' : ''}`}>
      <span className="chyron__tag">{tag}</span>
      <span className="chyron__val">{value}</span>
    </div>
  );
}

// ---- legal documents ----
export type DocBlock = { type: 'p' | 'ul'; text: string; items: string[] };
export type DocSection = { heading: string; blocks: DocBlock[] };
export type LegalDocData = {
  docTitle: string;
  plainSummary: string;
  sections: DocSection[];
  reviewNotes: string[];
};

export function LegalDoc({ kicker, updated, data }: { kicker: string; updated: string; data: LegalDocData }) {
  return (
    <main>
      <SiteHeader />
      <article className="doc">
        <div className="doc__kicker">{kicker}</div>
        <h1>{data.docTitle}</h1>
        <div className="doc__meta">last updated · {updated}</div>
        <p className="doc__summary">{data.plainSummary}</p>

        {data.sections.map((s, i) => (
          <section key={i}>
            <h2>{s.heading}</h2>
            {s.blocks.map((b, j) =>
              b.type === 'ul' ? (
                <ul key={j}>
                  {b.items.map((it, k) => (
                    <li key={k}>{it}</li>
                  ))}
                </ul>
              ) : (
                <p key={j}>{b.text}</p>
              ),
            )}
          </section>
        ))}

        {/* Internal pre-publish checklist — hidden on the public site. The notes
            live in the source (legal-data.ts) + COMPLIANCE.md. Set
            SHOW_LEGAL_REVIEW_NOTES=1 to preview them in a non-production build. */}
        {process.env.SHOW_LEGAL_REVIEW_NOTES === '1' && data.reviewNotes.length > 0 && (
          <div className="doc__review">
            <strong>Owner to confirm before publishing:</strong>
            <ul style={{ marginTop: 8 }}>
              {data.reviewNotes.map((n, i) => (
                <li key={i} style={{ listStyle: 'disc', marginLeft: 18 }}>{n}</li>
              ))}
            </ul>
          </div>
        )}
      </article>
      <SiteFooter />
    </main>
  );
}
