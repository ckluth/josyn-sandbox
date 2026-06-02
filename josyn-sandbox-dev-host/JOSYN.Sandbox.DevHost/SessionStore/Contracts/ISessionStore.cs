using JOSYN.Foundation.ResultPattern;

namespace JOSYN.Sandbox.DevHost;

public interface ISessionStore
{
    Result SaveNewSessionInfo(IJobSessionInfo jobSessionInfo);

    Result<IJobSessionInfo> GetSessionInfo(string sessionUid);
    
    Result UpdateSessionInfo(IJobSessionInfo jobSessionInfo);
}