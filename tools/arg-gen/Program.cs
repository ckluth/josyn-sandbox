using ArgGen;

// ---------------------------------------------------------------------------
// Usage: ArgGen.exe <job-exe-path> --cli-path <cli-exe-path> [--output-dir <dir>]
// ---------------------------------------------------------------------------

if (args.Length < 3)
{
    Console.Error.WriteLine("Usage: ArgGen.exe <job-exe-path> --cli-path <cli-exe-path> [--output-dir <dir>]");
    return 1;
}

var jobExePath = args[0];
string? cliPath    = null;
string? outputDir  = null;

for (var i = 1; i < args.Length - 1; i++)
{
    if (args[i] == "--cli-path")   cliPath   = args[i + 1];
    if (args[i] == "--output-dir") outputDir = args[i + 1];
}

if (string.IsNullOrWhiteSpace(cliPath))
{
    Console.Error.WriteLine("Error: --cli-path is required.");
    return 1;
}

if (!File.Exists(jobExePath))
{
    Console.Error.WriteLine($"Error: Job executable not found: {jobExePath}");
    return 1;
}

try
{
    var descriptor = JobLoader.Load(jobExePath);

    if (descriptor.Parameters.Count == 0)
    {
        Console.Error.WriteLine($"Info: {descriptor.JobName} has no [JobEntryPoint] parameters — no scaffold generated.");
        return 0;
    }

    var targetDir = outputDir
        ?? Path.Combine(Path.GetDirectoryName(Path.GetFullPath(jobExePath))!, "local-arguments");

    Directory.CreateDirectory(targetDir);

    var iniPath          = Path.Combine(targetDir, "arguments-default.ini");
    var launcherCmdPath  = Path.Combine(targetDir, "_launcher.cmd");
    var defaultCmdPath   = Path.Combine(targetDir, "arguments-default.cmd");

    File.WriteAllText(iniPath,         ScaffoldGenerator.GenerateIni(descriptor));
    File.WriteAllText(launcherCmdPath, ScaffoldGenerator.GenerateLauncherCmd(descriptor, cliPath));
    File.WriteAllText(defaultCmdPath,  ScaffoldGenerator.GenerateDefaultCmd());

    Console.WriteLine($"[ArgGen] Scaffold written to: {targetDir}");
    Console.WriteLine($"  {Path.GetFileName(iniPath)}");
    Console.WriteLine($"  {Path.GetFileName(launcherCmdPath)}");
    Console.WriteLine($"  {Path.GetFileName(defaultCmdPath)}");

    return 0;
}
catch (Exception ex)
{
    Console.Error.WriteLine($"Error: {ex.Message}");
    return 1;
}
