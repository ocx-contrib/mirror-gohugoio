# hugo/tests/smoke.star — stable across upstream Hugo releases.
# Asserts the contract (version shape, the EDITION actually shipped, the
# platform actually shipped, and a real site build whose output contains a
# value the input does not), never help/version prose.
#
# ⚠ THE ASSERTION THIS PACKAGE EXISTS FOR IS THE EDITION CHECK. Upstream ships
# FOUR variants of every release from one tag — base (`hugo_`), extended
# (`hugo_extended_`), withdeploy (`hugo_withdeploy_`) and extended_withdeploy
# (`hugo_extended_withdeploy_`). This mirror carries EXTENDED. The platform
# gate cannot see the difference: all four ship a binary called `hugo` for
# `linux/amd64`, so a wrong asset regex produces a green run publishing the
# wrong edition. Two independent runtime discriminators are asserted below,
# both measured on v0.164.0 base vs extended (same tag, same commit):
#
#   base      hugo version -> "hugo v0.164.0-ce2470e7…            linux/amd64 …"
#   extended  hugo version -> "hugo v0.164.0-ce2470e7…+extended   linux/amd64 …"
#
#   base      hugo env     -> github.com/webmproject/libwebp="v1.6.0"
#   extended  hugo env     -> github.com/webmproject/libwebp="v1.6.0"
#                             github.com/sass/libsass="3.6.6"      <- extended only
#
# `hugo env` is the stronger of the two: it names the embedded C++ Sass library
# that is the reason the extended binary links libstdc++.so.6 at all, so it
# cannot be satisfied by a version banner alone.
#
# HOME is set explicitly on every run. Hugo resolves a module/file cache under
# the user home directory, and the container legs run as uid 0 with HOME unset
# or unwritable — a tool that persists state under $HOME exits non-zero there
# while passing on a developer workstation.

HUGO = "hugo.exe" if ocx.target_platform.os == ocx.os.Windows else "hugo"

# Point every Hugo cache at the test sandbox. USERPROFILE is the Windows
# spelling Go's os.UserHomeDir reads; setting both keeps one dict for all
# platforms.
ENV = {"HOME": ocx.scratch_root, "USERPROFILE": ocx.scratch_root}

# ── Tier 1 + 2: liveness on the composed PATH + version SHAPE ───────────────
# The digits are the contract; the banner around them is not.
r_version = ocx.run(HUGO, "version", env=ENV)
expect.ok(r_version)
expect.matches(r_version.stdout, r"\d+\.\d+\.\d+")

# ── Edition proof #1 — this bundle carries the EXTENDED asset ───────────────
# Absent from the base variant of the very same tag (measured above).
expect.contains(r_version.stdout, "+extended")

# ── Edition proof #2 + free platform identity ───────────────────────────────
r_env = ocx.run(HUGO, "env", env=ENV)
expect.ok(r_env)
# libsass is compiled into the extended edition only.
expect.contains(r_env.stdout, "github.com/sass/libsass=")
# `hugo env` reports GOOS/GOARCH in exactly the OCI spellings ocx uses, so this
# proves the asset regex put the right artifact in the right bundle — the one
# bug class the platform gate cannot see from inside.
expect.contains(r_env.stdout, "GOOS=\"" + str(ocx.target_platform.os) + "\"")
expect.contains(r_env.stdout, "GOARCH=\"" + str(ocx.target_platform.arch) + "\"")

# ── Tier 3: build a real site, offline, on hermetic input ───────────────────
# A bare `hugo new site` renders nothing (no layouts), so the layout, the
# stylesheet and the content are all written here. No theme is fetched and no
# network is touched — themes need the network, a hand-written layout does not.
ocx.mkdir("site/layouts")
ocx.mkdir("site/assets")
ocx.mkdir("site/content")

ocx.write_file("site/hugo.toml", "baseURL = \"https://example.org/\"\ntitle = \"ocx smoke\"\n")

# Nested rule + an arithmetic expression. The transpiled output must contain
# `84px` and the FLATTENED selector `.ocx .inner`; neither string appears
# anywhere in this input. That is the negative control against a tool that
# merely copied its input through — a passthrough passes a "the CSS is there"
# check and fails this one.
ocx.write_file("site/assets/main.scss", "$w: 42px;\n.ocx { .inner { width: $w * 2; } }\n")

ocx.write_file(
    "site/layouts/index.html",
    "{{ $css := resources.Get \"main.scss\" | css.Sass }}"
    + "OCXCSS[{{ $css.Content }}]OCXPAGES[{{ len site.RegularPages }}]\n",
)
ocx.write_file("site/content/hello.md", "---\ntitle: hello\n---\nbody\n")

# `--destination` resolves against `--source`, so the output lands at
# site/out/ (measured — not site-adjacent).
r_build = ocx.run(HUGO, "--source", "site", "--destination", "out", "--logLevel", "error", env=ENV)
expect.ok(r_build)

html = ocx.read_file("site/out/index.html")

# The computed value, and the selector Sass had to flatten to produce it.
expect.contains(html, "84px")
expect.contains(html, ".ocx .inner")
# Content discovery worked: exactly one regular page was found and counted.
# A build that rendered the template but walked no content prints OCXPAGES[0].
expect.contains(html, "OCXPAGES[1]")
