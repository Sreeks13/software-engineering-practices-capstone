using RoomKeeper;

namespace RoomKeeper.Tests;

public static class DeskTests
{
    public static void Run(Action<bool, string> check)
    {
        string path = Path.Combine(Path.GetTempPath(),
            $"roomkeeper-{Guid.NewGuid():N}.log");

        try
        {
            var desk = new BookingDesk(new AvailabilityLedger(), new AuditLog(path));
            var request = new BookingRequest("Taylor", 102,
                new DateOnly(2026, 12, 1), new DateOnly(2026, 12, 4), 2);

            check(desk.Submit(request, out _), "Valid booking should be accepted.");
            check(File.Exists(path), "Audit log should be created.");
            check(File.ReadAllText(path).Contains("BOOKING_ACCEPTED"),
                "Audit log should record the decision.");
        }
        finally
        {
            if (File.Exists(path))
                File.Delete(path);
        }
    }
}
