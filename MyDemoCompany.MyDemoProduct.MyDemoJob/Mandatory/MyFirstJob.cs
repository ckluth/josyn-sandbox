using JOSYN.JobHost.Attributes;

namespace MyDemoCompany.MyDemoProduct.MyDemoJob;

public static class MyFirstJob
{
    [JobEntryPoint]
    public static MyResult Execute(MyArguments args)
    {
        Console.WriteLine($"\nExecuting MyFirstJob with: {args.Msg}");

        return new MyResult
        {
            Count = args.Count + 1,
            Message = "Echo: " + args.Msg,
            Succeeded = true,
        };
    }

    #region Placeholder hooks — not yet invoked by runtime

    [BeforeJobEntryPoint]
    internal static void Initialize()
    {
        // Reserved for pre-job setup (e.g. configuring parallel execution policy).
        // BeforeJobEntryPointAttribute is not yet invoked — planned for a future milestone.
    }

    #endregion
}

