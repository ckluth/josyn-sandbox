using Markdig;
using Markdig.Renderers;
using Markdig.Syntax;
using Markdig.Syntax.Inlines;

static class PageRenderer
{
    public static string Render(
        SiteBuilder.Page page,
        List<SiteBuilder.NavSection> navSections,
        string sourceDir,
        string siteTitle)
    {
        var markdown = File.ReadAllText(page.SourcePath);
        var document = Markdown.Parse(markdown, SiteBuilder.Pipeline);

        RewriteLinks(document, page, sourceDir);

        var title = ExtractTitle(document)
            ?? SiteBuilder.FormatName(Path.GetFileNameWithoutExtension(page.RelativeSource));

        var writer = new StringWriter();
        var renderer = new HtmlRenderer(writer);
        SiteBuilder.Pipeline.Setup(renderer);
        renderer.Render(document);
        var contentHtml = writer.ToString();

        var navHtml = BuildNavHtml(page, navSections);

        var depth = page.RelativeOutput
            .Split([Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar]).Length - 1;
        var cssPath = depth > 0
            ? string.Concat(Enumerable.Repeat("../", depth)) + "site.css"
            : "site.css";

        return HtmlTemplate.Render(title, siteTitle, cssPath, navHtml, contentHtml);
    }

    static void RewriteLinks(MarkdownDocument document, SiteBuilder.Page currentPage, string sourceDir)
    {
        var currentSourceDir = Path.GetDirectoryName(currentPage.RelativeSource) ?? "";
        var currentOutputDir = Path.GetDirectoryName(currentPage.RelativeOutput) ?? "";

        foreach (var link in document.Descendants<LinkInline>())
        {
            if (link.Url is null || IsAbsolute(link.Url)) continue;

            var fragmentIdx = link.Url.IndexOf('#');
            var pathPart = fragmentIdx >= 0 ? link.Url[..fragmentIdx] : link.Url;
            var fragment = fragmentIdx >= 0 ? link.Url[fragmentIdx..] : "";

            // Directory-style links → rewrite to index.html in that directory
            if (pathPart.EndsWith('/'))
            {
                var resolvedDir = Path.GetFullPath(Path.Combine(sourceDir, currentSourceDir, pathPart));
                var readmePath = Path.Combine(resolvedDir, "README.md");
                if (File.Exists(readmePath))
                {
                    var relSource = Path.GetRelativePath(sourceDir, readmePath);
                    if (!relSource.StartsWith(".."))
                    {
                        var targetOutput = SiteBuilder.ToOutputPath(relSource);
                        link.Url = ComputeRelativeHref(currentOutputDir, targetOutput) + fragment;
                    }
                }
                continue;
            }

            if (!pathPart.EndsWith(".md", StringComparison.OrdinalIgnoreCase))
                continue;

            var resolvedSourcePath = Path.GetFullPath(Path.Combine(sourceDir, currentSourceDir, pathPart));
            var resolvedRelativeSource = Path.GetRelativePath(sourceDir, resolvedSourcePath);

            if (resolvedRelativeSource.StartsWith(".."))
                continue; // outside source tree, leave as-is

            var targetRelativeOutput = SiteBuilder.ToOutputPath(resolvedRelativeSource);
            link.Url = ComputeRelativeHref(currentOutputDir, targetRelativeOutput) + fragment;
        }
    }

    static string? ExtractTitle(MarkdownDocument document)
    {
        var h1 = document.Descendants<HeadingBlock>().FirstOrDefault(h => h.Level == 1);
        if (h1?.Inline is null) return null;

        var sb = new System.Text.StringBuilder();
        foreach (var literal in h1.Inline.Descendants<LiteralInline>())
            sb.Append(literal.Content.ToString());

        return sb.Length > 0 ? sb.ToString() : null;
    }

    static string BuildNavHtml(SiteBuilder.Page currentPage, List<SiteBuilder.NavSection> navSections)
    {
        var sb = new System.Text.StringBuilder();
        var currentOutputDir = Path.GetDirectoryName(currentPage.RelativeOutput) ?? "";

        foreach (var section in navSections)
        {
            if (section.Landing is not null && section.Children.Count == 0)
            {
                // Simple top-level link (e.g. Home)
                var href = ComputeRelativeHref(currentOutputDir, section.Landing.RelativeOutput);
                var active = currentPage.RelativeOutput == section.Landing.RelativeOutput ? " active" : "";
                sb.AppendLine($"<a href=\"{href}\" class=\"nav-home{active}\">{Encode(section.Title)}</a>");
            }
            else
            {
                sb.AppendLine($"<div class=\"nav-section\">{Encode(section.Title)}</div>");

                if (section.Landing is not null)
                {
                    var href = ComputeRelativeHref(currentOutputDir, section.Landing.RelativeOutput);
                    var active = currentPage.RelativeOutput == section.Landing.RelativeOutput ? " active" : "";
                    sb.AppendLine($"<a href=\"{href}\" class=\"nav-link{active}\">Overview</a>");
                }

                foreach (var navPage in section.Children)
                {
                    var href = ComputeRelativeHref(currentOutputDir, navPage.RelativeOutput);
                    var active = currentPage.RelativeOutput == navPage.RelativeOutput ? " active" : "";
                    sb.AppendLine($"<a href=\"{href}\" class=\"nav-link{active}\">{Encode(navPage.Title)}</a>");
                }
            }
        }

        return sb.ToString();
    }

    // Computes relative href from a directory to a file, both relative to the site root.
    // Uses a dummy absolute root so Path.GetRelativePath works correctly with relative inputs.
    internal static string ComputeRelativeHref(string fromDir, string toPath)
    {
        const string root = "C:\\__site__";
        var absFrom = fromDir.Length > 0 ? Path.Combine(root, fromDir) : root;
        var absTo = Path.Combine(root, toPath);
        return Path.GetRelativePath(absFrom, absTo).Replace('\\', '/');
    }

    static bool IsAbsolute(string url) =>
        url.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
        url.StartsWith("https://", StringComparison.OrdinalIgnoreCase) ||
        url.StartsWith("mailto:", StringComparison.OrdinalIgnoreCase) ||
        url.StartsWith('#');

    static string Encode(string text) => System.Net.WebUtility.HtmlEncode(text);
}
