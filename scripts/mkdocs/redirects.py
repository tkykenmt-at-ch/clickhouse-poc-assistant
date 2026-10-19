"""MkDocs hook: keep the URLs of the earlier Jekyll site working, and keep the English 404 page.

The Japanese pages used to be <page>.ja.html and are now ja/<page>.html. The skill and the plans it wrote link to
the old URLs, often with an anchor, so each old URL gets a small page that forwards to the new one with the anchor.
"""

from pathlib import Path

PAGES = ["index", "setup", "walkthrough", "development"]

TEMPLATE = """<!doctype html>
<html lang="ja">
<head>
<meta charset="utf-8">
<title>Redirecting…</title>
<link rel="canonical" href="{target}">
<script>location.replace("{target}" + location.hash);</script>
<meta http-equiv="refresh" content="0; url={target}">
</head>
<body><a href="{target}">{target}</a></body>
</html>
"""


_english_404 = None


def on_post_template(output, template_name, config, **kwargs):
    # The i18n plugin's Japanese build writes its own 404.html over the English one at the top; keep the English one.
    global _english_404
    if template_name == "404.html" and config["theme"]["language"] == "en":
        _english_404 = output
    return output


def on_post_build(config, **kwargs):
    # This runs after the English build and again after the Japanese one, which ends last; site_dir is the top of
    # the site both times, so writing the same files twice is harmless.
    site = Path(config["site_dir"])
    if _english_404 is not None:
        (site / "404.html").write_text(_english_404, encoding="utf-8")
    for page in PAGES:
        (site / f"{page}.ja.html").write_text(TEMPLATE.format(target=f"ja/{page}.html"), encoding="utf-8")
