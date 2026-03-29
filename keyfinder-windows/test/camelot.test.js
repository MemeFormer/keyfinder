const { keyToCamelot, keyToShortName } = require('../camelot');

test('C Major maps to 8B', () => {
  expect(keyToCamelot('C Major')).toBe('8B');
});

test('A Minor maps to 8A', () => {
  expect(keyToCamelot('A Minor')).toBe('8A');
});

test('F# Minor maps to 11A', () => {
  expect(keyToCamelot('F# Minor')).toBe('11A');
});

test('C Major short name is C', () => {
  expect(keyToShortName('C Major')).toBe('C');
});

test('C Minor short name is Cm', () => {
  expect(keyToShortName('C Minor')).toBe('Cm');
});

test('unknown key returns empty string', () => {
  expect(keyToCamelot('Nonsense')).toBe('');
});
