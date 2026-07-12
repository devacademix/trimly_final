import type { MetadataRoute } from 'next';

// This is an internal super-admin surface — keep it out of search indexes,
// on top of the per-page `robots: noindex` metadata. /privacy and /terms are
// the two exceptions: they're public legal pages meant to be found (app
// store listings link to them, and they're useful to have indexed).
export default function robots(): MetadataRoute.Robots {
  return {
    rules: { userAgent: '*', allow: ['/privacy', '/terms'], disallow: '/' },
  };
}
