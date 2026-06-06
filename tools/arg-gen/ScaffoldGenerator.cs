using System.Globalization;
using System.Reflection;
using System.Text;

namespace ArgGen;

internal static class ScaffoldGenerator
{
    private static readonly CultureInfo DeDe = new("de-DE");

    internal static string GenerateIni(JobEntryDescriptor descriptor)
    {
        var sb = new StringBuilder();

        if (descriptor.Parameters.Count > 0)
        {
            var recordTypeName = GetRecordTypeName(descriptor);
            if (recordTypeName is not null)
                sb.AppendLine($"; {recordTypeName}");
        }

        foreach (var p in descriptor.Parameters)
            sb.AppendLine($"{p.Name}={GetPlaceholder(p)}");

        return sb.ToString();
    }

    internal static string GenerateLauncherCmd(JobEntryDescriptor descriptor, string cliPath)
    {
        var sb = new StringBuilder();
        sb.AppendLine("@echo off");
        sb.AppendLine("CHCP 1252 >nul");
        sb.AppendLine();
        sb.AppendLine("if \"%~1\"==\"\" (");
        sb.AppendLine("    echo.");
        sb.AppendLine("    echo  Diese Datei ist nicht zum direkten Aufruf gedacht.");
        sb.AppendLine("    echo  Bitte eine der arguments-*.cmd Dateien in diesem Ordner verwenden.");
        sb.AppendLine("    echo.");
        sb.AppendLine("    pause");
        sb.AppendLine("    exit /b 1");
        sb.AppendLine(")");
        sb.AppendLine();
        sb.AppendLine($"set JOSYN_CLI={cliPath}");
        sb.AppendLine($"set JOB_NAME={descriptor.JobName}");
        sb.AppendLine();
        sb.AppendLine("echo.");
        sb.AppendLine("echo  Job:   %JOB_NAME%");
        sb.AppendLine("echo  Args:  %~nx1");
        sb.AppendLine("echo.");
        sb.AppendLine();
        sb.AppendLine("set /p CONFIRM=\"ENTER zum Starten, CTRL-C zum Abbrechen... \"");
        sb.AppendLine();
        sb.AppendLine("echo.");
        sb.AppendLine("\"%JOSYN_CLI%\" run-job \"%JOB_NAME%\" \"%~1\"");
        sb.Append("exit /b %ERRORLEVEL%");
        return sb.ToString();
    }

    internal static string GenerateDefaultCmd()
        => "@call \"%~dp0_launcher.cmd\" \"%~dp0arguments-default.ini\"";

    private static string? GetRecordTypeName(JobEntryDescriptor descriptor)
        => descriptor.RecordTypeName;

    private static string GetPlaceholder(ParamInfo p)
    {
        if (p.IsNullableValueType)
            return string.Empty;

        var type = p.Type;

        if (type.IsEnum)
            return type.GetFields(BindingFlags.Public | BindingFlags.Static)
                       .FirstOrDefault()?.Name ?? string.Empty;

        return type.FullName switch
        {
            "System.String"                                          => string.Empty,
            "System.Char"                                            => "A",
            "System.Boolean"                                         => "False",
            "System.Byte" or "System.SByte"
                or "System.Int16" or "System.UInt16"
                or "System.Int32" or "System.UInt32"
                or "System.Int64" or "System.UInt64"                 => "0",
            "System.Single" or "System.Double" or "System.Decimal"  => "0,00",
            "System.DateTime"  => DateTime.Today.ToString("dd.MM.yyyy HH:mm:ss", DeDe),
            "System.DateTimeOffset" => DateTimeOffset.Now.ToString("dd.MM.yyyy HH:mm:ss zzz", DeDe),
            "System.DateOnly"  => DateOnly.FromDateTime(DateTime.Today).ToString("dd.MM.yyyy", DeDe),
            "System.TimeOnly"  => "00:00:00",
            "System.TimeSpan"  => "00:00:00",
            "System.Guid"      => "00000000-0000-0000-0000-000000000000",
            _                  => string.Empty
        };
    }
}
