namespace JOSYN.Sandbox.DevHost;

public sealed record JobSessionInfo : IJobSessionInfo
{
    public required Guid UID { get; init; }
    public required string JobTypeName { get; init; }
    public required string Arguments { get; init; }
    public required string Result { get; init; }
}