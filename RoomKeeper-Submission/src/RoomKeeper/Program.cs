namespace RoomKeeper;

internal static class Program
{
    private static void Main(string[] args)
    {
        if (args.Contains("--perf"))
        {
            PerfComparison.Run();
            return;
        }

        var ledger = new AvailabilityLedger();
        var audit = new AuditLog("audit.log");
        var desk = new BookingDesk(ledger, audit);

        Console.WriteLine("RoomKeeper - Hotel Booking Validator");
        Console.WriteLine("Rooms: " +
            string.Join(", ", RoomCatalog.Rooms.Select(r =>
                $"{r.Id} ({r.Name}, capacity {r.Capacity})")));
        Console.WriteLine("Enter: guest|roomId|yyyy-MM-dd|yyyy-MM-dd|guests");
        Console.WriteLine("Type 'exit' to quit.");

        while (true)
        {
            Console.Write("> ");
            string? line = Console.ReadLine();

            if (line is null || line.Equals("exit", StringComparison.OrdinalIgnoreCase))
                break;

            if (!BookingParser.TryParse(line, out var request, out string error))
            {
                Console.WriteLine($"Invalid input: {error}");
                audit.Record("INPUT_REJECTED", error);
                continue;
            }

            bool accepted = desk.Submit(request!, out string message);
            Console.WriteLine($"{(accepted ? "SUCCESS" : "REJECTED")}: {message}");
        }
    }
}
