#!/usr/bin/env node
/**
 * Generate deterministic moon reference fixture from canonical SunCalc equations.
 *
 * Source equations: mourner/suncalc (BSD-2-Clause), getMoonIllumination.
 * Output: test/fixtures/moon/suncalc_reference.json
 */

import { writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDir = dirname(fileURLToPath(import.meta.url));
const outFile = resolve(scriptDir, '../test/fixtures/moon/suncalc_reference.json');

const PI = Math.PI;
const RAD = PI / 180;
const OBLIQUITY = RAD * 23.4397;

function toJulian(date) {
  return date.valueOf() / 86400000 - 0.5 + 2440588;
}

function toDays(date) {
  return toJulian(date) - 2451545;
}

function rightAscension(l, b) {
  return Math.atan2(
    Math.sin(l) * Math.cos(OBLIQUITY) - Math.tan(b) * Math.sin(OBLIQUITY),
    Math.cos(l),
  );
}

function declination(l, b) {
  return Math.asin(
    Math.sin(b) * Math.cos(OBLIQUITY) + Math.cos(b) * Math.sin(OBLIQUITY) * Math.sin(l),
  );
}

function sunCoords(d) {
  const M = RAD * (357.5291 + 0.98560028 * d);
  const C = RAD * (1.9148 * Math.sin(M) + 0.02 * Math.sin(2 * M) + 0.0003 * Math.sin(3 * M));
  const P = RAD * 102.9372;
  const L = M + C + P + PI;
  return { dec: declination(L, 0), ra: rightAscension(L, 0) };
}

function moonCoords(d) {
  const L = RAD * (218.316 + 13.176396 * d);
  const M = RAD * (134.963 + 13.064993 * d);
  const F = RAD * (93.272 + 13.22935 * d);
  const l = L + RAD * 6.289 * Math.sin(M);
  const b = RAD * 5.128 * Math.sin(F);
  const dist = 385001 - 20905 * Math.cos(M);
  return { ra: rightAscension(l, b), dec: declination(l, b), dist };
}

function getMoonIllumination(unixSeconds) {
  const d = toDays(new Date(unixSeconds * 1000));
  const s = sunCoords(d);
  const m = moonCoords(d);
  const sdist = 149598000;

  const phi = Math.acos(
    Math.sin(s.dec) * Math.sin(m.dec) +
      Math.cos(s.dec) * Math.cos(m.dec) * Math.cos(s.ra - m.ra),
  );

  const inc = Math.atan2(sdist * Math.sin(phi), m.dist - sdist * Math.cos(phi));
  const angle = Math.atan2(
    Math.cos(s.dec) * Math.sin(s.ra - m.ra),
    Math.sin(s.dec) * Math.cos(m.dec) -
      Math.cos(s.dec) * Math.sin(m.dec) * Math.cos(s.ra - m.ra),
  );

  return {
    illumination: ((1 + Math.cos(inc)) / 2) * 100,
    phase_fraction: 0.5 + (0.5 * inc * (angle < 0 ? -1 : 1)) / PI,
  };
}

function phaseName(phaseFraction) {
  const bucket = Math.floor(phaseFraction * 8);
  switch (bucket) {
    case 0:
      return 'New Moon';
    case 1:
      return 'Waxing Crescent';
    case 2:
      return 'First Quarter';
    case 3:
      return 'Waxing Gibbous';
    case 4:
      return 'Full Moon';
    case 5:
      return 'Waning Gibbous';
    case 6:
      return 'Last Quarter';
    default:
      return 'Waning Crescent';
  }
}

// 6-hour cadence gives strong coverage around phase transitions and time handling.
const startUnix = Date.UTC(2025, 0, 1, 0, 0, 0) / 1000;
const count = 520;
const stepSeconds = 6 * 3600;

const samples = [];
for (let i = 0; i < count; i += 1) {
  const unix = startUnix + i * stepSeconds;
  const moon = getMoonIllumination(unix);
  const phase_fraction = ((moon.phase_fraction % 1) + 1) % 1;
  const illumination = moon.illumination;
  samples.push({
    unix,
    phase_fraction: Number(phase_fraction.toFixed(12)),
    illumination: Number(illumination.toFixed(9)),
    phase: phaseName(phase_fraction),
  });
}

const fixture = {
  source: 'SunCalc canonical equations (mourner/suncalc, BSD-2-Clause)',
  generated_at_utc: new Date().toISOString(),
  cadence_hours: 6,
  timezone: 'UTC',
  notes: 'All timestamps are absolute Unix seconds in UTC; compare at exact instant, not local day.',
  samples,
};

writeFileSync(outFile, `${JSON.stringify(fixture, null, 2)}\n`, 'utf8');
console.log(`Wrote ${samples.length} samples to ${outFile}`);
