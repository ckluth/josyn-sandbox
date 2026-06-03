using JOSYN.Foundation.ResultPattern;

namespace JOSYN.Sandbox.DevHost;

public interface ISessionStore
{
    Result SaveNewSession(IJobSession jobSession);

    Result<IJobSession> GetSession(string sessionUid);
    
    Result UpdateSession(IJobSession jobSession);
}