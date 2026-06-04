using Markdig;

static class SiteBuilder
{
    internal static readonly MarkdownPipeline Pipeline = new MarkdownPipelineBuilder()
        .UseAdvancedExtensions()
        .Build();

    public static void Build(string sourceDir, string outputDir, string? siteTitle = null)
    {
        Directory.CreateDirectory(outputDir);

        siteTitle ??= FormatName(Path.GetFileName(sourceDir.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar)));
        var pages = DiscoverPages(sourceDir);
        var navSections = BuildNav(pages);

        foreach (var page in pages)
        {
            var html = PageRenderer.Render(page, navSections, sourceDir, siteTitle);
            var outputPath = Path.Combine(outputDir, page.RelativeOutput);
            Directory.CreateDirectory(Path.GetDirectoryName(outputPath)!);
            File.WriteAllText(outputPath, html, System.Text.Encoding.UTF8);
        }

        File.WriteAllText(Path.Combine(outputDir, "site.css"), HtmlTemplate.Css);

        Console.WriteLine($"Generated {pages.Count} pages → {outputDir}");
    }

    internal record Page(string SourcePath, string RelativeSource, string RelativeOutput);

    static List<Page> DiscoverPages(string sourceDir) =>
        Directory
            .GetFiles(sourceDir, "*.md", SearchOption.AllDirectories)
            .Select(sourcePath =>
            {
                var rel = Path.GetRelativePath(sourceDir, sourcePath);
                return new Page(sourcePath, rel, ToOutputPath(rel));
            })
            .OrderBy(p => p.RelativeSource)
            .ToList();

    internal static string ToOutputPath(string relativeSourcePath)
    {
        var fileName = Path.GetFileName(relativeSourcePath);
        var dir = Path.GetDirectoryName(relativeSourcePath) ?? "";

        var outputFileName = fileName.Equals("README.md", StringComparison.OrdinalIgnoreCase)
            ? "index.html"
            : Path.ChangeExtension(fileName, ".html");

        return dir.Length > 0 ? Path.Combine(dir, outputFileName) : outputFileName;
    }

    internal record NavPage(string Title, string RelativeOutput);

    internal record NavSection(string Title, NavPage? Landing, List<NavPage> Children);

    static List<NavSection> BuildNav(List<Page> pages)
    {
        var sections = new List<NavSection>();

        var homePage = pages.FirstOrDefault(p => p.RelativeOutput == "index.html");
        if (homePage is not null)
        {
            var homeTitle = ExtractTitle(homePage.SourcePath) ?? "Home";
            sections.Add(new NavSection(homeTitle, new NavPage(homeTitle, "index.html"), []));
        }

        var byFolder = pages
            .Where(p => {
                var parts = p.RelativeOutput.Split([Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar]);
                return parts.Length > 1;
            })
            .GroupBy(p => p.RelativeOutput.Split([Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar])[0])
            .OrderBy(g => g.Key);

        foreach (var group in byFolder)
        {
            var sectionTitle = FormatFolderName(group.Key);
            var landing = group.FirstOrDefault(p => Path.GetFileName(p.RelativeOutput) == "index.html");

            var children = group
                .Where(p => p != landing)
                .Select(p => new NavPage(
                    ExtractTitle(p.SourcePath) ?? FormatName(Path.GetFileNameWithoutExtension(p.RelativeSource)),
                    p.RelativeOutput))
                .ToList();

            var landingNav = landing is null ? null : new NavPage(sectionTitle, landing.RelativeOutput);
            sections.Add(new NavSection(sectionTitle, landingNav, children));
        }

        return sections;
    }

    static string? ExtractTitle(string sourcePath)
    {
        foreach (var line in File.ReadLines(sourcePath))
        {
            var trimmed = line.TrimStart();
            if (trimmed.StartsWith("# "))
                return trimmed[2..].Trim();
            if (trimmed.Length > 0 && !trimmed.StartsWith('#'))
                break; // title must come before any non-heading content
        }
        return null;
    }

    internal static string FormatFolderName(string folderName)
    {
        var withoutNumber = System.Text.RegularExpressions.Regex.Replace(folderName, @"^\d+[-_]?", "");
        return FormatName(withoutNumber);
    }

    internal static string FormatName(string name)
    {
        var words = name.Replace('-', ' ').Replace('_', ' ')
                        .Split(' ', StringSplitOptions.RemoveEmptyEntries);
        return string.Join(" ", words.Select(w => char.ToUpper(w[0]) + w[1..]));
    }
}
