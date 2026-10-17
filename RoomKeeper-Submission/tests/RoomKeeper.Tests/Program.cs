namespace RoomKeeper.Tests;

internal static class Program
{
    private static int _passed;
    private static int _failed;

    private static void Check(bool condition, string message)
    {
        if (condition)
        {
            _passed++;
            Console.WriteLine($"PASS: {message}");
        }
        else
        {
            _failed++;
            Console.WriteLine($"FAIL: {message}");
        }
    }

    private static void Main()
    {
        ParserTests.Run(Check);
        CheckTests.Run(Check);
        SupportTests.Run(Check);
        DeskTests.Run(Check);

        Console.WriteLine($"\nPassed: {_passed}; Failed: {_failed}");
        if (_failed > 0)
            Environment.ExitCode = 1;
    }
}
