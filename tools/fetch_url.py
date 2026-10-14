#!/usr/bin/env python3
"""Fetch a page from clickhouse.com and print it, or only some of its sections.

Used by the skills through the code tool, for pages that change and must be read live
(for example https://clickhouse.com/pricing.md). Only https://clickhouse.com/ URLs are fetched,
redirects are followed only within that host, and at most 2 MB is read.

Usage:
  python3 fetch_url.py <url> [--section "<heading>"]...
  python3 fetch_url.py https://clickhouse.com/pricing.md --section "How pricing is calculated" --section "Compute & storage rates by region"

A section is a Markdown heading (any level) and everything up to the next heading of the
same or a higher level. Headings are matched without the leading #s, case-insensitively.
"""
import argparse
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone

ALLOWED_HOST = 'clickhouse.com'
MAX_BYTES = 2_000_000


def allowed(url):
    u = urllib.parse.urlparse(url)
    return u.scheme == 'https' and u.hostname == ALLOWED_HOST and u.port in (None, 443)


class SameHostRedirects(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        if not allowed(newurl):
            raise urllib.error.URLError(f'redirect to a URL outside https://{ALLOWED_HOST}/ refused: {newurl}')
        return super().redirect_request(req, fp, code, msg, headers, newurl)


def sections(text, wanted):
    wanted = {w.strip().lower() for w in wanted}
    out, level = [], None
    for line in text.splitlines():
        if line.startswith('#'):
            hashes = len(line) - len(line.lstrip('#'))
            title = line[hashes:].strip().lower()
            if level is not None and hashes <= level:
                level = None
            if level is None and title in wanted:
                level = hashes
                wanted.discard(title)
        if level is not None:
            out.append(line)
    return '\n'.join(out), wanted


def main():
    ap = argparse.ArgumentParser(description='Fetch a clickhouse.com page.')
    ap.add_argument('url')
    ap.add_argument('--section', action='append', default=[], help='heading to keep (repeatable)')
    a = ap.parse_args()
    if not allowed(a.url):
        sys.exit(f'ERROR: only https://{ALLOWED_HOST}/ URLs are fetched')
    opener = urllib.request.build_opener(SameHostRedirects())
    req = urllib.request.Request(a.url, headers={'User-Agent': 'clickhouse-poc-assistant'})
    try:
        with opener.open(req, timeout=30) as r:
            if not allowed(r.geturl()):
                sys.exit(f'ERROR: ended outside https://{ALLOWED_HOST}/: {r.geturl()}')
            raw = r.read(MAX_BYTES + 1)
        if len(raw) > MAX_BYTES:
            sys.exit(f'ERROR: {a.url} is larger than {MAX_BYTES} bytes')
        text = raw.decode('utf-8', 'replace')
    except (urllib.error.URLError, OSError) as e:
        sys.exit(f'ERROR: could not fetch {a.url}: {e}')
    print(f'Fetched {a.url} at {datetime.now(timezone.utc):%Y-%m-%d %H:%M} UTC')
    print()
    if not a.section:
        print(text)
        return
    body, missing = sections(text, a.section)
    print(body)
    if missing:
        print(f'\nNOT FOUND: sections {sorted(missing)}', file=sys.stderr)
        sys.exit(2)


if __name__ == '__main__':
    main()
