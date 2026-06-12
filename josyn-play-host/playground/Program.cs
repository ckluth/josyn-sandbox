using JOSYN.Commons.Log;

namespace playground
{
    internal class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("Hello, World!");

            var result = Turnstile.Run("DebugLog", () =>
            {
                Console.WriteLine("concurrency - safe here!");
            });

            if (result.Succeeded)
            {
                Console.WriteLine("Operation succeeded.");
            }
            else
            {
                Console.WriteLine(result.ErrorMessage);
            }

            Console.ReadKey(true);
        }
    }
}
