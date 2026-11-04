import { render } from 'pele';
import { Resvg } from '@resvg/resvg-js';
import { readFileSync, writeFileSync } from 'node:fs';

try {
  const source = readFileSync(0, 'utf8');
  if (source.length > 100000) throw new Error('Diagram exceeds 100 KB');
  const palette = JSON.parse(process.argv[3] ?? '{}');
  for (const [name, value] of Object.entries(palette)) {
    if (!/^--pele-[a-z0-9-]+$/.test(name) || !/^#[0-9a-f]{6}$/i.test(value)) throw new Error('Invalid theme color');
  }
  let { svg } = render(source);
  // resvg does not evaluate CSS variables. Resolve Pele's inline defaults.
  const variables = {};
  for (const [, name, value] of svg.matchAll(/(--[\w-]+):([^;"<>]+)/g)) variables[name] = value;
  Object.assign(variables, palette);
  for (let pass = 0; pass < 12 && svg.includes('var('); pass++) {
    svg = svg.replace(/var\((--[\w-]+)(?:,([^()]*))?\)/g, (_, name, fallback) => variables[name] ?? fallback ?? 'black');
  }
  const renderer = new Resvg(svg, { background: palette['--pele-bg'] ?? 'white', fitTo: { mode: 'width', value: 1200 }, font: { loadSystemFonts: true } });
  writeFileSync(process.argv[2], renderer.render().asPng());
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
}
