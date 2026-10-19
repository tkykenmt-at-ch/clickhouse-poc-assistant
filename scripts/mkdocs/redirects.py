"""MkDocs hook: keep the URLs of the earlier Jekyll site working.

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


def on_post_build(config, **kwargs):
    site = Path(config["site_dir"])
    # The i18n plugin builds the Japanese pages into site/ja with the same hooks; write only at the top.
    if site.name == "ja":
        return
    for page in PAGES:
        (site / f"{page}.ja.html").write_text(TEMPLATE.format(target=f"ja/{page}.html"), encoding="utf-8")
