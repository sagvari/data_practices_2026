#!/bin/sh

set -eu

ROOT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
OUTPUT_FILE="${1:-index.html}"
OUTPUT_PATH="${ROOT_DIR}/${OUTPUT_FILE}"
TMP_FILE=$(mktemp "${TMPDIR:-/tmp}/generate_index.XXXXXX")
FILES_FILE=$(mktemp "${TMPDIR:-/tmp}/generate_index_files.XXXXXX")

cleanup() {
  rm -f "$TMP_FILE" "$FILES_FILE"
}

trap cleanup EXIT INT TERM

html_escape() {
  printf '%s' "$1" | sed \
    -e 's/&/\&amp;/g' \
    -e 's/</\&lt;/g' \
    -e 's/>/\&gt;/g' \
    -e 's/"/\&quot;/g' \
    -e "s/'/\&#39;/g"
}

url_encode_path() {
  printf '%s' "$1" | sed \
    -e 's/%/%25/g' \
    -e 's/ /%20/g' \
    -e 's/#/%23/g' \
    -e 's/?/%3F/g' \
    -e 's/&/%26/g'
}

remote_url=$(git -C "$ROOT_DIR" config --get remote.origin.url 2>/dev/null || true)
if [ -z "$remote_url" ]; then
  echo "Could not determine git remote 'origin'." >&2
  exit 1
fi

owner_repo=$(printf '%s\n' "$remote_url" | sed -E \
  -e 's#^git@github.com:##' \
  -e 's#^https://github.com/##' \
  -e 's#^http://github.com/##' \
  -e 's#\.git$##')

case "$owner_repo" in
  */*)
    owner=${owner_repo%%/*}
    repo=${owner_repo##*/}
    ;;
  *)
    echo "Could not parse GitHub repository from origin URL: $remote_url" >&2
    exit 1
    ;;
esac

if [ "$repo" = "$owner.github.io" ]; then
  base_url="https://${owner}.github.io"
else
  base_url="https://${owner}.github.io/${repo}"
fi

find "$ROOT_DIR" -type f -name '*.html' ! -path "$OUTPUT_PATH" ! -name 'header.html' -print | \
  sed "s#^${ROOT_DIR}/##" | \
  LC_ALL=C sort > "$FILES_FILE"

cat > "$TMP_FILE" <<EOF
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>${repo} - HTML Launcher</title>
  <style>
    :root {
      --bg: #eef3f8;
      --panel: #ffffff;
      --text: #1f2937;
      --muted: #4b5563;
      --line: #d7e2ee;
      --link: #0f4f9c;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      padding: 32px 20px;
      background: linear-gradient(180deg, #f8fbff 0%, var(--bg) 100%);
      color: var(--text);
      font-family: Arial, Helvetica, sans-serif;
    }
    main {
      max-width: 960px;
      margin: 0 auto;
      background: var(--panel);
      border: 1px solid var(--line);
      border-radius: 14px;
      padding: 28px;
      box-shadow: 0 10px 30px rgba(15, 23, 42, 0.06);
    }
    h1 {
      margin: 0 0 8px;
      font-size: 1.8rem;
    }
    p {
      margin: 0 0 14px;
      color: var(--muted);
      line-height: 1.5;
    }
    ul {
      margin: 18px 0 0;
      padding-left: 20px;
    }
    li {
      margin: 10px 0;
    }
    a {
      color: var(--link);
      text-decoration: none;
    }
    a:hover {
      text-decoration: underline;
    }
    code {
      background: #f3f4f6;
      border: 1px solid #e5e7eb;
      border-radius: 5px;
      padding: 2px 6px;
    }
  </style>
</head>
<body>
  <main>
    <h1>${repo} HTML Launcher</h1>
    <p>Generated from local repository contents. Each link opens the GitHub Pages URL for the matching HTML file.</p>
    <p>Base URL: <code>${base_url}</code></p>
    <ul>
EOF

if [ -s "$FILES_FILE" ]; then
  while IFS= read -r rel_path; do
    escaped_label=$(html_escape "$rel_path")
    encoded_path=$(url_encode_path "$rel_path")
    url=$(html_escape "${base_url}/${encoded_path}")
    printf '      <li><a href="%s">%s</a></li>\n' "$url" "$escaped_label" >> "$TMP_FILE"
  done < "$FILES_FILE"
else
  printf '      <li>No HTML files found.</li>\n' >> "$TMP_FILE"
fi

cat >> "$TMP_FILE" <<EOF
    </ul>
  </main>
</body>
</html>
EOF

mv "$TMP_FILE" "$OUTPUT_PATH"

echo "Generated ${OUTPUT_FILE} with $(wc -l < "$FILES_FILE" | tr -d ' ') HTML link(s)."
