import React from 'react';

export type FiltersState = {
  windMetrics: Set<'gust' | 'sustained'>;
  minSeverity: 1 | 2 | 3 | 4 | 5;
  windowHours: number; // 0–72
  crewRec?: number;
};

export function FiltersPanel(props: {
  value: FiltersState;
  onChange: (next: FiltersState) => void;
}) {
  const { value, onChange } = props;

  function toggleWind(metric: 'gust' | 'sustained') {
    const next = new Set(value.windMetrics);
    next.has(metric) ? next.delete(metric) : next.add(metric);
    onChange({ ...value, windMetrics: next });
  }

  return (
    <section className="filters sticky" aria-label="Filters">
      <div className="filters-row">
        <div className="filter-group">
          <div className="label">Wind Metric</div>
          <div className="chip-row">
            <button
              className={`chip ${value.windMetrics.has('gust') ? 'selected' : ''}`}
              aria-pressed={value.windMetrics.has('gust')}
              onClick={() => toggleWind('gust')}
            >
              ✓ Gust
            </button>
            <button
              className={`chip ${value.windMetrics.has('sustained') ? 'selected' : ''}`}
              aria-pressed={value.windMetrics.has('sustained')}
              onClick={() => toggleWind('sustained')}
            >
              ✓ Sustained
            </button>
          </div>
        </div>

        <div className="filter-group">
          <div className="label">Minimum Threat Level</div>
          <div className="chip-row">
            {[1,2,3,4,5].map(n => (
              <button
                key={n}
                className={`chip ${value.minSeverity === n ? 'selected' : ''}`}
                aria-pressed={value.minSeverity === n}
                onClick={() => onChange({ ...value, minSeverity: n as FiltersState['minSeverity'] })}
              >
                Min Sev {n}
              </button>
            ))}
          </div>
        </div>

        <div className="filter-group">
          <label htmlFor="window" className="label">Window (hours)</label>
          <input
            id="window"
            type="range"
            min={0}
            max={72}
            value={value.windowHours}
            onChange={e => onChange({ ...value, windowHours: Number(e.target.value) })}
          />
          <div className="range-value">{value.windowHours}h</div>
        </div>
      </div>
    </section>
  );
}