if (args.Length < 2)
{
    Console.Error.WriteLine("Usage: DocGenerator <source-dir> <output-dir> [<site-title>]");
    return 1;
}

var sourceDir = Path.GetFullPath(args[0]);
var outputDir = Path.GetFullPath(args[1]);
var siteTitle = args.Length >= 3 ? args[2] : null;

if (!Directory.Exists(sourceDir))
{
    Console.Error.WriteLine($"Source directory not found: {sourceDir}");
    return 1;
}

SiteBuilder.Build(sourceDir, outputDir, siteTitle);
return 0;
