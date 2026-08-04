# NOTICE

This repository packages and redistributes upstream software published by the
[Hugo](https://github.com/gohugoio/hugo) project. The Apache-2.0 license in
[`LICENSE`](LICENSE) covers the OCX pipeline files authored here. It does
**not** cover any upstream-derived asset — each package's redistributed bytes
carry their own license, recorded below.

Each package's logo in this repository reproduces the **upstream project's own
mark** at 512 px, unmodified apart from scaling, solely to identify the
software being mirrored. No endorsement or affiliation is implied, and no
trademark right is claimed.

| Package | GHCR path | Upstream SPDX |
|---|---|---|
| `hugo` | `ghcr.io/ocx-contrib/gohugoio/hugo` | `Apache-2.0` |

---

## `hugo`

Upstream: <https://github.com/gohugoio/hugo>
Published to `ghcr.io/ocx-contrib/gohugoio/hugo`.

| Component | SPDX | Holder |
|---|---|---|
| Hugo (`hugo`) | **Apache-2.0** | Copyright The Hugo Authors |

Verified with `gh api repos/gohugoio/hugo/license --jq .license.spdx_id`, which
answers `Apache-2.0`, and against the `LICENSE` file at the repository root.

The Apache License 2.0 grants redistribution of the work in source and object
form, on the conditions that recipients receive a copy of the license, that
modified files are marked, and that any `NOTICE` text is carried forward. Those
conditions are met by construction: upstream's `LICENSE` file ships **inside
every mirrored archive**, at the archive root beside the binary, and is
republished unmodified as part of the bundle content. No modifications are made
to any upstream artifact in this repository; they are republished
byte-for-byte inside an OCX bundle.

The mirrored artifacts are the **extended** edition (`hugo_extended_*`). That
edition statically embeds [libsass](https://github.com/sass/libsass)
(**MIT**, Copyright (c) 2016 Sass) and links
[libwebp](https://chromium.googlesource.com/webm/libwebp) (**BSD-3-Clause**,
Copyright (c) 2010, Google Inc.); both are reported by the binary itself via
`hugo env`. The published binaries additionally statically link third-party Go
modules under permissive licenses, enumerated in the `go.mod`/`go.sum` of the
tagged upstream source for each mirrored version.
