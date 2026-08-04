# mirror-gohugoio

OCX mirror for [Hugo](https://github.com/gohugoio/hugo), the static site
generator. One repository, one spec directory per package.

| Package | Spec | Publishes to | Announced as | Upstream SPDX |
|---|---|---|---|---|
| [hugo](https://github.com/gohugoio/hugo) | [`hugo/mirror.yml`](hugo/mirror.yml) | `ghcr.io/ocx-contrib/gohugoio/hugo` | [`ocx.sh/gohugoio/hugo`](https://index.ocx.sh/gohugoio/hugo) | `Apache-2.0` |

Each upstream release is discovered, re-bundled, smoke-tested per
`(version, platform)` and only then pushed with cascade tags, after which the
result is announced into the OCX index.

The GitHub org is the project's own brand, so the org names the namespace and
the tool names the package: `gohugoio/hugo`.

## Layout

```
hugo/
├── mirror.yml          the spec — never at the repo root
├── metadata.json       bundle interface
├── CATALOG.md          → ocx package describe
├── logo.svg / logo.png describe assets, 512px PNG
└── tests/smoke.star    Starlark smoke test
```

`LICENSE` and `NOTICE.md` are shared at the root. The logo is not — it lives
beside the spec, because a repo-root `logo.*` sits in no workflow's `paths:`
filter, so replacing it would publish nothing until some unrelated edit
happened to fire.

There is deliberately **no `mirror-base.yml` and no `extends:`**. This repo
holds one package and every key is package-owned, so a base would carry no
repo-wide policy — and `extends:` is a *shallow* merge of top-level keys whose
classic failure is a child restating `platforms:` to change one runner and
silently dropping every `containers:` entry with it. Nothing reds; the legs
simply stop existing and every `os.features` claim goes back to being asserted
rather than verified. One file removes that trap structurally. A second package
here would add a sibling directory and only then a base — a content move that
renames no generated workflow file.

## The edition trap

Upstream ships **four** editions of every release from a single tag:

| Prefix | Edition | Mirrored |
|---|---|---|
| `hugo_` | base | no |
| `hugo_extended_` | extended (embeds libsass) | **yes** |
| `hugo_withdeploy_` | base + `hugo deploy` | no |
| `hugo_extended_withdeploy_` | both | no |

All four ship a binary named `hugo` for the same platforms, so **the platform
gate cannot tell them apart** — a wrong asset pattern yields a fully green run
publishing the wrong edition. Two runtime discriminators were measured on
v0.164.0 (same tag, same commit) and both are asserted by
[`hugo/tests/smoke.star`](hugo/tests/smoke.star) on every version and platform:

```
base      hugo version → hugo v0.164.0-ce2470e7…          linux/amd64 …
extended  hugo version → hugo v0.164.0-ce2470e7…+extended linux/amd64 …

base      hugo env     → github.com/webmproject/libwebp="v1.6.0"
extended  hugo env     → github.com/webmproject/libwebp="v1.6.0"
                         github.com/sass/libsass="3.6.6"        ← extended only
```

Two asset-name traps follow from the same release layout, and both live on
every release in range:

1. `hugo_extended_withdeploy_<V>_…` shares the `hugo_extended_` prefix. Every
   pattern requires `\d+\.\d+\.\d+` immediately after that prefix, so
   `withdeploy_` cannot match.
2. A **duplicate linux-amd64 alias** ships beside the canonical name, for the
   same platform, in every edition:
   `hugo_extended_<V>_Linux-64bit.tar.gz` (capital L, legacy) alongside
   `hugo_extended_<V>_linux-amd64.tar.gz`. A case-insensitive or substring
   pattern double-matches these into an ambiguous-match error. Both names span
   the whole in-range window, so neither is a mid-range format sibling; the
   canonical lowercase name is anchored exactly and the alias is left alone.

`.deb` siblings and the shared `hugo_<V>_checksums.txt` are kept out by the
`\.tar\.gz$` / `\.zip$` end anchors.

Resolution was verified **both ways on every in-range release** (v0.163.2,
v0.163.3, v0.164.0): each declared pattern matches exactly one asset, every
time, and every asset name embeds the version of the tag carrying it. A pattern
matching zero would be silently skipped rather than reported, so this check is
not optional.

## Platforms

`linux/amd64+libc.glibc`, `linux/arm64+libc.glibc`, `windows/amd64`.

### These Linux keys are `+libc.glibc`, not bare

The extended edition is a **cgo** build — that is how libsass gets in — so
unlike most Go tools on this fleet it is not static. Measured on both arches at
both ends of the mirrored range (0.163.2 and 0.164.0), all four artifacts
identical: `dynamically linked`, one `PT_INTERP`
(`/lib64/ld-linux-x86-64.so.2`, `/lib/ld-linux-aarch64.so.1`), and four
`DT_NEEDED` entries — `libstdc++.so.6`, `libm.so.6`, `libgcc_s.so.1`,
`libc.so.6`. Symbol floors are `GLIBC_2.34` and `GLIBCXX_3.4.29`, the same on
both arches. Not UPX-packed (zero `^UPX` strings, full section headers), so
`file` is trustworthy here.

`os.features` states what an artifact **requires of the host**, so both Linux
keys carry `+libc.glibc`. A bare key would be a false universality claim; the
negative control is decisive:

| Stock image | `hugo version` |
|---|---|
| `ubuntu:24.04` | exit 0 |
| `fedora:40` | exit 0 |
| `alpine:3.20` | `exec /b/hugo: no such file or directory` |

Container legs are therefore ubuntu + fedora — two glibc vintages — and **not**
alpine. An alpine leg on a glibc key is a leg that cannot pass, which is
exactly what the key already says.

No `containers[].setup:` line is needed anywhere, and that is measured rather
than assumed: `libstdc++.so.6` and `libgcc_s.so.1` are already present in the
stock ubuntu and fedora images, as the two exit-0 runs above show. Adding a
`libstdc++` install would make those legs prove *less* — the honest claim is
"runs on the stock image".

### `darwin` is deliberately excluded — upstream ships `.pkg` only

Every one of the four editions ships macOS solely as
`hugo[_extended][_withdeploy]_<V>_darwin-universal.pkg`. **No darwin `.tar.gz`
or `.zip` exists for Hugo at all**, on any release in the fetched history — so
this is not a matter of picking a different asset. `.pkg` is a xar archive
wrapping cpio payloads, and the bundle pipeline's extractor supports gzip/xz/
zstd tarballs, zip and raw uncompressed binaries only. Improvising xar+cpio
extraction is out of scope for a mirror, whose value is republishing upstream
bytes unmodified. macOS users should `brew install hugo`.

This is a permanent format gap, not a staged pass: there is no darwin key
pre-written in `hugo/mirror.yml`, because there would be nothing to uncomment.

### `windows/arm64` is deliberately excluded — not shipped in this edition

`hugo_<V>_windows-arm64.zip` exists only in the **base** edition. The
`extended`, `withdeploy` and `extended_withdeploy` editions ship no
windows-arm64 asset on any release in range, so an extended windows/arm64
pattern would match **zero** assets — and a declared platform that resolves no
asset does not red. It boots a real `windows-11-arm` runner and reports SUCCESS
having tested nothing. Mirroring it would mean switching the whole package to
the base edition and losing libsass, so it is not pre-written as a comment
either.

### Not expressible in OCX

Upstream also ships `linux-arm` (32-bit) and `freebsd`/`netbsd`/`openbsd`/
`solaris`/`dragonfly` amd64 builds — base edition only. OCX's
`OperatingSystem` enum is Linux/Darwin/Windows and its `Architecture` enum is
amd64/arm64, so none of these is a declarable platform.

## Editing

| File | Edit | Regenerate after |
|------|------|------------------|
| `hugo/mirror.yml` | hand | yes — see below |
| `hugo/{metadata.json,CATALOG.md,logo.*}` | hand | — |
| `hugo/tests/smoke.star` | hand | — |
| `.github/workflows/*.yml` | **generated — never hand-edit** | re-run when a spec changes |

```bash
ocx-mirror package pipeline generate ci --spec hugo/mirror.yml
```

**Name every spec.** `--spec` *appends* rather than replaces, so a command
naming a subset silently stops rendering the rest while staying green — and the
drift guard reds on a generated workflow the current spec set no longer
produces.

`verify-generated.yml` exits 65 on drift. If a generated workflow is wrong, the
spec or the renderer template is wrong — fix it there and regenerate.

Run `direnv allow` once to put the pinned toolchain on `PATH`, and invoke
`ocx-mirror` directly — never `ocx run -- ocx-mirror`, which pins
`OCX_BINARY_PIN` to the bootstrap `ocx` and false-reds the nested push.

## The binaries claim

`hugo/metadata.json` declares `binaries: ["hugo"]` by hand, and
`hugo/mirror.yml` sets `bin_scan: off` — forced, not preferred. The scan only
inspects an interface-visible `${installPath}/<dir>` PATH entry, and Hugo's
archives are **flat**: `hugo(.exe)`, `README.md` and `LICENSE` sit at the
archive root with no subdirectory to point one at. With nothing to inspect the
scan would pass green whatever the archive contained, so `auto` and `verify`
both fail spec load at exit 65 rather than offer a hollow check. The flat
layout is also why `strip_components` is **0**: on a flat archive
`strip_components: 1` deletes the top entry and hoists its siblings in its
place, silently dropping the binary.

## The smoke test

Beyond the two edition discriminators above, `hugo/tests/smoke.star` builds a
real site offline. It writes a config, a stylesheet, a layout and one content
page into the test sandbox, runs `hugo --source site --destination out`, and
reads the rendered HTML back.

The stylesheet is `$w: 42px; .ocx { .inner { width: $w * 2; } }`; the
assertions are that the output contains `84px` and the flattened selector
`.ocx .inner`. **Neither string appears anywhere in the input** — that is the
negative control. A tool that merely copied its input through would satisfy a
"the CSS is there" check and fail this one. The page count `OCXPAGES[1]` is
asserted alongside it, so a build that rendered the template but walked no
content also fails.

`hugo env` doubles as the free platform-identity check: it reports GOOS/GOARCH
in exactly the OCI spellings ocx uses, so `GOOS="linux"` / `GOARCH="arm64"`
proves the asset regex put the right artifact into the right bundle — the one
bug class the platform gate cannot see from inside.

`HOME` (and `USERPROFILE`) are set to the scratch root on every `ocx.run`.
Hugo resolves a file cache under the user home directory, and the container
legs run as uid 0 with `HOME` unset or unwritable.

## Required secrets

| Secret | Use |
|--------|-----|
| `OCX_ANNOUNCE_TOKEN` | opens the index pull request from the `ocx-contrib/index` fork |
| `OCX_MIRROR_DISCORD_HOOK` | notify-stage Discord webhook URL |

(Inherited from the `ocx-contrib` org with visibility ALL. GHCR pushes use the
run's own `GITHUB_TOKEN` — no registry secret needed.)

## License

Apache-2.0 — see [`LICENSE`](LICENSE). Upstream assets are out of scope; each
package's redistribution license is recorded in [`NOTICE.md`](NOTICE.md). The
logo reproduces upstream's own mark, unmodified apart from scaling, solely to
identify the software being mirrored.
