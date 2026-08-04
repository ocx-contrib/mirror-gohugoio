---
title: Hugo
description: The world's fastest static site generator — builds a whole site from Markdown, templates and assets in milliseconds, with a built-in asset pipeline
keywords: hugo,static-site-generator,ssg,jamstack,markdown,templates,blog,website,sass,scss,go,cli
---

# Hugo

[Hugo](https://gohugo.io) turns a directory of Markdown, templates and assets
into a complete static website. It is a single self-contained binary with no
runtime dependencies: content in `content/`, layouts in `layouts/`, and an
asset pipeline (Sass/SCSS, PostCSS, minification, fingerprinting, image
processing) reachable straight from templates. Builds of a few thousand pages
finish in well under a second, and `hugo server` rebuilds and live-reloads as
files change.

## What's included

- **hugo** — the binary. `hugo` builds the site in the current directory into
  `public/`, `hugo server` runs the live-reloading development server, and
  `hugo new site <path>` scaffolds a new project.

The archive also ships upstream's `LICENSE` and `README.md` alongside the
binary.

## Which edition this is

Upstream publishes four editions of every release. **This package mirrors the
`extended` edition**, which embeds libsass for Sass/SCSS transpilation. The
binary reports its own edition, and both signals are asserted by this package's
smoke test on every version and platform:

```sh
hugo version   # → hugo v0.164.0-…+extended linux/amd64 …
hugo env       # → github.com/sass/libsass="3.6.6"   (extended only)
```

The `withdeploy` editions, which add the `hugo deploy` command for pushing a
built site to S3/GCS/Azure, are **not** mirrored.

## Platforms

`linux/amd64`, `linux/arm64` and `windows/amd64`.

**macOS is not available from this mirror.** Upstream ships macOS solely as a
`.pkg` installer (`hugo_extended_<version>_darwin-universal.pkg`) — there is no
darwin tarball or zip for any edition, on any release. `.pkg` is a xar archive
wrapping cpio payloads, which the OCX bundle pipeline does not extract. Install
Hugo on macOS with `brew install hugo`.

**`windows/arm64` is not available either**: upstream ships a Windows ARM64
build only in the *base* edition, never in `extended`.

## Runtime requirement

The extended edition is a cgo build, so unlike most Go tools it is dynamically
linked: it requires a **glibc** userland plus `libstdc++.so.6` and
`libgcc_s.so.1` (both present in stock `ubuntu:24.04` and `fedora:40`). It does
**not** run on musl systems such as Alpine — the platform keys say
`+libc.glibc` for exactly that reason.

## Usage

```sh
# scaffold, then build
hugo new site mysite
cd mysite && hugo
```

```sh
# live-reloading dev server, including draft content
hugo server --buildDrafts
```

```sh
# production build with minification, into a chosen directory
hugo --minify --destination dist
```

Sass/SCSS is transpiled from templates via `css.Sass`, which is what the
extended edition provides:

```go-html-template
{{ $css := resources.Get "main.scss" | css.Sass | resources.Minify }}
<link rel="stylesheet" href="{{ $css.RelPermalink }}">
```

## Install with ocx

```sh
ocx install ocx.sh/gohugoio/hugo
```

```sh
# or pin a specific version
ocx install ocx.sh/gohugoio/hugo:0.164.0
```

## Links

- [Hugo on GitHub](https://github.com/gohugoio/hugo)
- [gohugo.io](https://gohugo.io)
- [Documentation](https://gohugo.io/documentation/)
- [Editions explained](https://gohugo.io/installation/#editions)
- [Themes](https://themes.gohugo.io)
