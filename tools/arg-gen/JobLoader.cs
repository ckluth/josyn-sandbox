using System.Reflection;
using System.Runtime.Loader;

namespace ArgGen;

internal sealed record ParamInfo(string Name, Type Type, bool IsNullableValueType);

internal sealed record JobEntryDescriptor(string JobName, IReadOnlyList<ParamInfo> Parameters, string? RecordTypeName = null);

internal static class JobLoader
{
    internal static JobEntryDescriptor Load(string jobExePath)
    {
        var jobName = Path.GetFileNameWithoutExtension(jobExePath);
        var jobDir  = Path.GetDirectoryName(Path.GetFullPath(jobExePath))!;

        // The .exe is a native AppHost wrapper. The actual IL assembly is the .dll.
        var assemblyPath = Path.Combine(jobDir, jobName + ".dll");
        if (!File.Exists(assemblyPath))
            throw new FileNotFoundException(
                $"Assembly not found alongside exe (expected: {assemblyPath}).");

        var ctx = new JobAssemblyLoadContext(jobDir);
        var asm = ctx.LoadFromAssemblyPath(assemblyPath);

        var entryMethod = FindEntryMethod(asm);

        var parameters = entryMethod.GetParameters();
        if (parameters.Length == 0)
            return new JobEntryDescriptor(jobName, []);

        var isSingleRecord = parameters.Length == 1
            && parameters[0].ParameterType.GetMethod("<Clone>$") is not null;

        var recordTypeName = isSingleRecord ? parameters[0].ParameterType.Name : null;

        var paramInfos = isSingleRecord
            ? FromRecord(parameters[0].ParameterType)
            : FromParameters(parameters);

        return new JobEntryDescriptor(jobName, paramInfos, recordTypeName);
    }

    private static MethodInfo FindEntryMethod(Assembly asm)
    {
        var candidates = asm.GetExportedTypes()
            .SelectMany(t => t.GetMethods(BindingFlags.Public | BindingFlags.Static))
            .Where(m => m.CustomAttributes
                .Any(a => a.AttributeType.Name == "JobEntryPointAttribute"))
            .ToList();

        return candidates.Count switch
        {
            0 => throw new InvalidOperationException(
                "No method with [JobEntryPoint] found in the assembly."),
            > 1 => throw new InvalidOperationException(
                "Multiple methods with [JobEntryPoint] found in the assembly."),
            _ => candidates[0]
        };
    }

    private static IReadOnlyList<ParamInfo> FromRecord(Type recordType)
    {
        return recordType
            .GetProperties(BindingFlags.Public | BindingFlags.Instance)
            .Select(p =>
            {
                var underlying = Nullable.GetUnderlyingType(p.PropertyType);
                return new ParamInfo(
                    p.Name,
                    underlying ?? p.PropertyType,
                    IsNullableValueType: underlying is not null);
            })
            .ToList();
    }

    private static IReadOnlyList<ParamInfo> FromParameters(ParameterInfo[] parameters)
    {
        return parameters
            .Select(p =>
            {
                var underlying = Nullable.GetUnderlyingType(p.ParameterType);
                return new ParamInfo(
                    p.Name!,
                    underlying ?? p.ParameterType,
                    IsNullableValueType: underlying is not null);
            })
            .ToList();
    }

    private sealed class JobAssemblyLoadContext : AssemblyLoadContext
    {
        private readonly string _jobDir;

        internal JobAssemblyLoadContext(string jobDir)
            : base("ArgGen", isCollectible: true) => _jobDir = jobDir;

        protected override Assembly? Load(AssemblyName assemblyName)
        {
            var path = Path.Combine(_jobDir, assemblyName.Name + ".dll");
            return File.Exists(path) ? LoadFromAssemblyPath(path) : null;
        }
    }
}
