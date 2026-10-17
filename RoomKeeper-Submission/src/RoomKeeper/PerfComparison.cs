using System.Diagnostics;

namespace RoomKeeper;

public static class PerfComparison
{
    public static void Run()
    {
        const int count = 100_000;
        var random = new Random(42);
        var values = Enumerable.Range(0, count)
            .Select(_ => random.Next(0, 1_000_000))
            .ToList();

        var set = new HashSet<int>(values);
        int target = values[^1];

        // Warm up before timing.
        _ = values.Contains(target);
        _ = set.Contains(target);

        var timer = Stopwatch.StartNew();
        bool listFound = values.Contains(target);
        timer.Stop();
        long listTicks = timer.ElapsedTicks;

        timer.Restart();
        bool setFound = set.Contains(target);
        timer.Stop();
        long setTicks = timer.ElapsedTicks;

        Console.WriteLine($"List found: {listFound}; ticks: {listTicks}");
        Console.WriteLine($"HashSet found: {setFound}; ticks: {setTicks}");
        Console.WriteLine("Timings vary by machine and data; repeat runs for reliable comparisons.");
    }
}
