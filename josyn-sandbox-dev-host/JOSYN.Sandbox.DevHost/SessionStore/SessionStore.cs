using JOSYN.Foundation.ResultPattern;

namespace JOSYN.Sandbox.DevHost;

public class SessionStore : ISessionStore
{
    public Result SaveNewSessionInfo(IJobSessionInfo jobSessionInfo)
    {
        throw new NotImplementedException();
    }

    public Result<IJobSessionInfo> GetSessionInfo(string sessionUid)
    {
        throw new NotImplementedException();
    }

    public Result UpdateSessionInfo(IJobSessionInfo jobSessionInfo)
    {
        throw new NotImplementedException();
    }
}