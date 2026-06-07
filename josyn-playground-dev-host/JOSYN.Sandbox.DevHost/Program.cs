namespace JOSYN.Sandbox.DevHost;

internal static class Program
{
    private const string ConnectionString =
        "Server=localhost\\SQLEXPRESS01;Database=josyn-db-local;User Id=tu.josyn;Password=josyn;TrustServerCertificate=True;";

    private static void Main(string[] args)
    {
        try
        {
            var store = new SessionStore(ConnectionString);

            // --- Save ---
            var session = new JobSession
            {
                UID = Guid.NewGuid(),
                JobTypeName = "JOSYN.Demo.SampleJob",
                Arguments = """{"target":"localhost","retries":3}""",
                Result = "pending"
            };

            Console.WriteLine($"Saving session {session.UID}...");
            var save = store.SaveNewSession(session);
            if (!save.Succeeded)
            {
                Console.WriteLine($"Save failed: {save.ErrorMessage}");
                return;
            }

            Console.WriteLine("Saved.");

            // --- Get ---
            Console.WriteLine($"Reading session {session.UID}...");
            var get = store.GetSession(session.UID.ToString());
            if (!get.Succeeded)
            {
                Console.WriteLine($"Get failed: {get.ErrorMessage}");
                return;
            }

            Console.WriteLine($"  JobTypeName : {get.Value!.JobTypeName}");
            Console.WriteLine($"  Arguments   : {get.Value.Arguments}");
            Console.WriteLine($"  Result      : {get.Value.Result}");

            // --- Update ---
            Console.WriteLine("Updating result to 'completed'...");
            var updated = session with { Result = "completed" };
            var update = store.UpdateSession(updated);
            if (!update.Succeeded)
            {
                Console.WriteLine($"Update failed: {update.ErrorMessage}");
                return;
            }

            Console.WriteLine("Updated.");

            // --- Verify ---
            var verify = store.GetSession(session.UID.ToString());
            if (verify.Succeeded)
                Console.WriteLine($"  Result after update: {verify.Value!.Result}");

        }
        catch (Exception ex)
        {
            Console.WriteLine(ex);
        }
        finally
        {
            Console.ReadKey();
        }
    }
}
