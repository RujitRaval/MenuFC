// FIFA 3-letter code (tla, as returned by football-data.org) -> ISO 3166-1 alpha-2.
// FIFA codes are NOT ISO codes (e.g. RSA=South Africa=ZA, GER=Germany=DE), and flag
// emoji are built from ISO-2 regional-indicator letters, so this lookup is required.
// Unknown codes fall back to ⚽ in flagFor(). Subdivisions (England/Scotland/Wales) have
// no ISO-2 + use dedicated emoji in SPECIAL_FLAGS below.
export const FIFA_TO_ISO2 = {
  // Hosts / CONCACAF
  USA: "US", MEX: "MX", CAN: "CA", CRC: "CR", PAN: "PA", HON: "HN", JAM: "JM",
  SLV: "SV", GUA: "GT", HAI: "HT", TRI: "TT", CUB: "CU", CUW: "CW", SUR: "SR",
  NCA: "NI", BLZ: "BZ", GRN: "GD", DMA: "DM", ATG: "AG", BRB: "BB",
  // CONMEBOL
  BRA: "BR", ARG: "AR", URU: "UY", COL: "CO", CHI: "CL", PER: "PE", ECU: "EC",
  PAR: "PY", BOL: "BO", VEN: "VE",
  // UEFA
  GER: "DE", FRA: "FR", ESP: "ES", ITA: "IT", NED: "NL", POR: "PT", BEL: "BE",
  CRO: "HR", DEN: "DK", SUI: "CH", SWE: "SE", POL: "PL", AUT: "AT", UKR: "UA",
  SRB: "RS", TUR: "TR", CZE: "CZ", ROU: "RO", HUN: "HU", RUS: "RU", NOR: "NO",
  IRL: "IE", ISL: "IS", GRE: "GR", SVK: "SK", SVN: "SI", BIH: "BA", ALB: "AL",
  BUL: "BG", FIN: "FI", MKD: "MK", MNE: "ME", GEO: "GE", ARM: "AM", AZE: "AZ",
  BLR: "BY", LUX: "LU", ISR: "IL", MDA: "MD", EST: "EE", LVA: "LV", LTU: "LT",
  CYP: "CY", MLT: "MT", NIR: "GB",
  // CAF
  SEN: "SN", MAR: "MA", TUN: "TN", ALG: "DZ", EGY: "EG", NGA: "NG", CMR: "CM",
  GHA: "GH", CIV: "CI", MLI: "ML", RSA: "ZA", COD: "CD", CGO: "CG", CPV: "CV",
  GAB: "GA", GUI: "GN", BFA: "BF", ZAM: "ZM", ANG: "AO", MOZ: "MZ", UGA: "UG",
  KEN: "KE", TAN: "TZ", BEN: "BJ", NAM: "NA", GNB: "GW", MTN: "MR", MAD: "MG",
  TOG: "TG", ZIM: "ZW", SUD: "SD", LBY: "LY", NIG: "NE", SLE: "SL", LBR: "LR",
  GAM: "GM", BDI: "BI", RWA: "RW", ETH: "ET", BOT: "BW", EQG: "GQ", COM: "KM",
  // AFC
  JPN: "JP", KOR: "KR", IRN: "IR", KSA: "SA", AUS: "AU", QAT: "QA", UAE: "AE",
  IRQ: "IQ", UZB: "UZ", JOR: "JO", CHN: "CN", OMA: "OM", BHR: "BH", PLE: "PS",
  KUW: "KW", IND: "IN", THA: "TH", VIE: "VN", SYR: "SY", LBN: "LB", PRK: "KP",
  TKM: "TM", KGZ: "KG", TJK: "TJ", MAS: "MY", IDN: "ID", PHI: "PH", YEM: "YE",
  // OFC
  NZL: "NZ", NCL: "NC", FIJ: "FJ", SOL: "SB", TAH: "PF", VAN: "VU", PNG: "PG",
};

// Codes with no usable ISO-2 flag emoji — map straight to an emoji.
export const SPECIAL_FLAGS = {
  ENG: "🏴\u{E0067}\u{E0062}\u{E0065}\u{E006E}\u{E0067}\u{E007F}", // England
  SCO: "🏴\u{E0067}\u{E0062}\u{E0073}\u{E0063}\u{E0074}\u{E007F}", // Scotland
  WAL: "🏴\u{E0067}\u{E0062}\u{E0077}\u{E006C}\u{E0073}\u{E007F}", // Wales
};

// tla -> flag emoji. Returns ⚽ for unknown/TBD so the client never shows a broken glyph.
export function flagFor(tla) {
  if (!tla) return "⚽";
  if (SPECIAL_FLAGS[tla]) return SPECIAL_FLAGS[tla];
  const iso2 = FIFA_TO_ISO2[tla];
  if (!iso2) return "⚽";
  return iso2.toUpperCase().replace(/./g, (c) =>
    String.fromCodePoint(0x1f1e6 - 65 + c.charCodeAt(0))
  );
}
