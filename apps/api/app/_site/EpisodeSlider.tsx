'use client';

import { useState } from 'react';

type Beat = { time: string; handle: string; text: string };
type Episode = { title: string; beats: readonly Beat[]; recap: string };

const chip: React.CSSProperties = {
  fontFamily: 'var(--font-mono)', fontSize: 12, fontWeight: 700, letterSpacing: '0.18em',
  textTransform: 'uppercase', color: 'var(--ink)', background: 'var(--acid)', padding: '4px 8px',
  flex: '0 0 auto',
};
const nav: React.CSSProperties = {
  fontFamily: 'var(--font-mono)', fontSize: 20, lineHeight: 1, color: 'var(--bone)',
  background: 'transparent', border: '1px solid var(--line)', width: 42, height: 38,
  cursor: 'pointer', display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
};

export function EpisodeSlider({ episodes }: { episodes: readonly Episode[] }) {
  const [i, setI] = useState(0);
  const [touchX, setTouchX] = useState<number | null>(null);
  const n = episodes.length;
  const ep = episodes[i]!;
  const go = (d: number) => setI((p) => (p + d + n) % n);

  return (
    <div
      style={{ maxWidth: 760 }}
      onTouchStart={(e) => setTouchX(e.touches[0]!.clientX)}
      onTouchEnd={(e) => {
        if (touchX == null) return;
        const dx = e.changedTouches[0]!.clientX - touchX;
        if (Math.abs(dx) > 40) go(dx < 0 ? 1 : -1);
        setTouchX(null);
      }}
    >
      {/* episode header + controls */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 12, marginBottom: 16, flexWrap: 'wrap' }}>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 12, flexWrap: 'wrap', minWidth: 0 }}>
          <span style={chip}>ep {String(i + 1).padStart(2, '0')}</span>
          <span style={{ fontFamily: 'var(--font-display)', fontSize: 'clamp(22px, 4.4vw, 34px)', textTransform: 'uppercase', lineHeight: 1 }}>{ep.title}</span>
        </div>
        <div style={{ display: 'flex', gap: 8, flex: '0 0 auto' }}>
          <button aria-label="previous episode" onClick={() => go(-1)} style={nav}>‹</button>
          <button aria-label="next episode" onClick={() => go(1)} style={nav}>›</button>
        </div>
      </div>

      {/* beats */}
      <div style={{ display: 'grid', gap: 12 }}>
        {ep.beats.map((b, j) => (
          <div key={j} style={{ background: 'var(--surface)', border: '1px solid var(--line)', borderLeft: `3px solid ${j % 2 === 0 ? 'var(--magenta)' : 'var(--acid)'}`, padding: '16px 18px' }}>
            <div style={{ fontFamily: 'var(--font-mono)', fontSize: 12, fontWeight: 700, letterSpacing: '0.08em', color: j % 2 === 0 ? 'var(--magenta)' : 'var(--acid)', marginBottom: 6 }}>
              @{b.handle}<span style={{ color: 'var(--bone-dim)', fontWeight: 400 }}>&nbsp;&nbsp;· {b.time}</span>
            </div>
            <p style={{ margin: 0, fontSize: 16, lineHeight: 1.5 }}>{b.text}</p>
          </div>
        ))}
      </div>

      {/* morning recap — the payoff */}
      <div style={{ marginTop: 12, padding: '18px 20px', background: 'var(--surface-lift)', borderLeft: '3px solid var(--bone)' }}>
        <div style={{ fontFamily: 'var(--font-mono)', fontSize: 12, fontWeight: 700, letterSpacing: '0.12em', textTransform: 'uppercase', color: 'var(--bone-dim)', marginBottom: 6 }}>8:00am · your recap</div>
        <p style={{ margin: 0, fontSize: 16, lineHeight: 1.5 }}>{ep.recap}</p>
      </div>

      {/* progress dots */}
      <div style={{ display: 'flex', gap: 6, marginTop: 18, alignItems: 'center' }}>
        {episodes.map((_, j) => (
          <button
            key={j}
            aria-label={`go to episode ${j + 1}`}
            onClick={() => setI(j)}
            style={{ width: j === i ? 24 : 9, height: 9, background: j === i ? 'var(--magenta)' : 'var(--line)', border: 'none', padding: 0, cursor: 'pointer', transition: 'width 0.2s, background 0.2s' }}
          />
        ))}
        <span style={{ marginLeft: 'auto', fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: '0.08em', color: 'var(--bone-dim)' }}>
          {String(i + 1).padStart(2, '0')} / {String(n).padStart(2, '0')}
        </span>
      </div>
    </div>
  );
}
