namespace JOSYN.Sandbox.DevHost;

public interface IJobSessionInfo
{
    Guid UID { get; init; }
    string JobTypeName { get; init; }
    string Arguments { get; init; }
    string Result { get; init; }
}