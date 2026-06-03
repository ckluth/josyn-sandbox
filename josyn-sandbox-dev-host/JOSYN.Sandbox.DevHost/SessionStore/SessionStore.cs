using JOSYN.Foundation.ResultPattern;
using Microsoft.EntityFrameworkCore;

namespace JOSYN.Sandbox.DevHost;

public class SessionStore(string connectionString) : ISessionStore
{
    public Result SaveNewSession(IJobSession jobSession)
    {
        try
        {
            using var ctx = new SessionStoreDbContext(connectionString);
            ctx.SessionStore.Add(new SessionStoreEntity
            {
                UID          = jobSession.UID,
                JobTypeName  = jobSession.JobTypeName,
                Arguments    = jobSession.Arguments,
                Result       = jobSession.Result
            });
            ctx.SaveChanges();
            return Result.Success;
        }
        catch (Exception ex) { return ex; }
    }

    public Result<IJobSession> GetSession(string sessionUid)
    {
        try
        {
            if (!Guid.TryParse(sessionUid, out var uid))
                return Result.Error($"'{sessionUid}' is not a valid GUID.");

            using var ctx = new SessionStoreDbContext(connectionString);
            var entity = ctx.SessionStore
                .AsNoTracking()
                .FirstOrDefault(entity => entity.UID == uid);

            if (entity is null)
                return Result.Error($"No session found for UID '{sessionUid}'.");

            return new JobSession
            {
                UID         = entity.UID,
                JobTypeName = entity.JobTypeName,
                Arguments   = entity.Arguments,
                Result      = entity.Result
            };
        }
        catch (Exception ex) { return ex; }
    }

    public Result UpdateSession(IJobSession jobSession)
    {
        try
        {
            using var ctx = new SessionStoreDbContext(connectionString);
            var entity = ctx.SessionStore.FirstOrDefault(entity => entity.UID == jobSession.UID);

            if (entity is null)
                return Result.Error($"No session found for UID '{jobSession.UID}'.");

            entity.JobTypeName = jobSession.JobTypeName;
            entity.Arguments   = jobSession.Arguments;
            entity.Result      = jobSession.Result;
            ctx.SaveChanges();
            return Result.Success;
        }
        catch (Exception ex) { return ex; }
    }
}