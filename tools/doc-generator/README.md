# doc-generator

A .NET 10 console tool that converts any well-structured markdown documentation tree
into a self-contained, browsable static HTML site. No server required — open
`index.html` directly from the file system.

Originally built for the JOSYN `solution-architecture` tree, but intentionally generic:
it works for any markdown tree that follows the conventions below.

---

## Usage

```
dotnet run --project tools/doc-generator -- <source-dir> <output-dir> [<site-title>]
```

All arguments are positional. `<site-title>` is optional.

| Argument | Description |
|----------|-------------|
| `<source-dir>` | Root of the markdown tree to export. Scanned recursively for `*.md` files. |
| `<output-dir>` | Destination folder for the generated site. Created if it does not exist. **Not a source repo folder** — point it anywhere (e.g. `C:\Temp\my-docs`). |
| `<site-title>` | *(Optional)* Title shown in the browser tab and sidebar header. If omitted, derived from the source directory name (e.g. `solution-architecture` → **Solution Architecture**). |

**Example** (from the `josyn-sandbox` root):

```
dotnet run --project tools/doc-generator -- ..\josyn-platform\solution-architecture C:\Temp\josyn-docs "JOSYN Architecture"
```

Then open `C:\Temp\josyn-docs\index.html` in any browser.

**Note:** because the CSS is compiled into the binary (not a loose file), any change to
`HtmlTemplate.cs` requires a rebuild. `dotnet run` (without `--no-build`) handles this
automatically. Use `--no-build` only when you have not changed any C# source.

---

## Source structure requirements

The tool makes these assumptions about the source tree:

### 1. A root `README.md` exists
It becomes `index.html` — the site's home page. Its first `# Heading` is used as the
page title.

### 2. Top-level numbered subdirectories form the nav sections
Directories whose names start with digits (e.g. `01-context`, `02-constraints-...`)
are treated as nav sections and sorted numerically. The number prefix is stripped for
display: `03-physical-architecture` → **Physical Architecture**.

Directories that do not start with digits are silently included but appear at the end
of the nav, unsorted.

### 3. Each section directory contains a `README.md`
This becomes `<section>/index.html` and is shown as the **Overview** link for that section.
Sections without a `README.md` still work — they just have no overview link.

### 4. All other `*.md` files are content pages
They are converted to `.html` alongside their `README.md`. Their first `# Heading` is
used as the nav label and page title.

### 5. Only one level of subdirectories is navigated
The sidebar shows sections → pages. Nested sub-subdirectories are converted to HTML but
are not represented in the nav — they are only reachable via internal links.

### What you do NOT need
- No `mkdocs.yml`, no `_config.yml`, no front-matter, no special metadata.
- No particular file naming beyond `README.md` for section landing pages.
- No assets — images and other binary files are not copied (markdown-only source).

---

## Output

The output folder is fully self-contained:

```
<output-dir>/
  site.css               ← single shared stylesheet
  index.html             ← home page (root README.md)
  01-context/
    index.html           ← section overview (README.md)
    josyn-and-jobsystem.html
  02-constraints.../
    index.html
    settled-decisions.html
  ...
```

All internal links (including cross-section `.md` links and directory-style links
ending in `/`) are rewritten to their HTML counterparts with correct relative paths.
No root-relative URLs are used, so the site works from `file://` without a web server.

---

## How it works (brief)

| File | Responsibility |
|------|---------------|
| `Program.cs` | Arg validation and entry point |
| `SiteBuilder.cs` | File discovery, nav tree construction, orchestration |
| `PageRenderer.cs` | Markdig AST parsing, link rewriting, per-page HTML assembly |
| `HtmlTemplate.cs` | HTML page template and CSS — the only file you need to touch for visual changes |

The pipeline per page:

1. Parse markdown to a Markdig AST.
2. Walk `LinkInline` nodes and rewrite local `.md` and directory-style (`/`) links
   to their output `.html` equivalents, computing relative paths from the current
   page's location.
3. Render the AST to an HTML fragment.
4. Wrap in the shared template with the page-specific nav sidebar.

---

## Tweaking and improving

### Changing the visual design

**All CSS lives in `HtmlTemplate.Css`** (a `const string` at the bottom of `HtmlTemplate.cs`).
Edit it freely — it is plain CSS, no preprocessor. The site uses:

- A fixed 280 px dark sidebar (`nav`)
- A content area with `max-width: 820px` (`article`)
- System font stack — no external font CDN

**The HTML template is `HtmlTemplate.Render()`** — a C# raw string literal at the top of
the same file. Add a `<footer>`, a breadcrumb, a header bar, or anything else here.

Placeholders injected into the template:

| Placeholder | Content |
|-------------|---------|
| `{title}` | Page title (first H1, HTML-encoded) |
| `{cssPath}` | Relative path to `site.css` from the current page |
| `{navHtml}` | Pre-rendered sidebar nav HTML |
| `{contentHtml}` | Rendered markdown body HTML |

### Changing the nav structure

Nav tree construction is in **`SiteBuilder.BuildNav()`**. Adjust:
- Section ordering (currently alphabetical within the `OrderBy(g => g.Key)` call)
- The label for the section landing page (currently hardcoded as `"Overview"` in
  `PageRenderer.BuildNavHtml()`)
- Support for nested sub-sections (requires adding a second tier to `NavSection`)

### Changing link rewriting behaviour

**`PageRenderer.RewriteLinks()`** walks the Markdig AST and rewrites `LinkInline.Url`
values in-place before rendering. Add cases here for:
- Rewriting anchor-only links (`#fragment`)
- Validating that rewritten targets actually exist in the output
- Handling image links (`link.IsImage`) — currently images are not rewritten or copied

### Adding a second Markdig extension

The pipeline is built once in `SiteBuilder`:

```csharp
internal static readonly MarkdownPipeline Pipeline = new MarkdownPipelineBuilder()
    .UseAdvancedExtensions()
    .Build();
```

`UseAdvancedExtensions()` already includes tables, task lists, footnotes, and
auto-identifiers. Add further extensions (e.g. `UseDiagrams()`) here.

### Supporting image assets

The tool currently ignores non-markdown files. To copy referenced images through:

1. Collect all `ImageInline` URLs in the AST before rendering.
2. Copy the referenced files from `sourceDir` to `outputDir` preserving relative paths.
3. No URL rewriting is needed since the output folder structure mirrors the source.

---

## Re-running after source changes

The tool is stateless — every run regenerates the entire output from scratch. There is
no incremental build. For a ~25-page tree, a full run completes in under one second.

To set up a fast edit–preview loop:
1. Edit a `.md` file.
2. Run `dotnet run --project tools/doc-generator --no-build -- <src> <out>`.
3. Refresh the browser.

No watch mode is provided, but nothing prevents wrapping this in a `while ($true)` loop
or a filesystem watcher script if you want automatic regeneration.
