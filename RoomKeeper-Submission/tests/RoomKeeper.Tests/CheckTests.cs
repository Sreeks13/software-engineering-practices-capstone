using RoomKeeper;

namespace RoomKeeper.Tests;

public static class CheckTests
{
    public static void Run(Action<bool, string> check)
    {
        var ledger = new AvailabilityLedger();
        var first = new BookingRequest("Alex", 101,
            new DateOnly(2026, 11, 1), new DateOnly(2026, 11, 3), 2);
        var overlap = new BookingRequest("Sam", 101,
            new DateOnly(2026, 11, 2), new DateOnly(2026, 11, 4), 1);
        var adjacent = new BookingRequest("Jo", 101,
            new DateOnly(2026, 11, 3), new DateOnly(2026, 11, 5), 2);

        check(ledger.TryBook(first, out _), "First booking should succeed.");
        check(!ledger.TryBook(overlap, out _), "Overlapping booking should fail.");
        check(ledger.TryBook(adjacent, out _),
            "Booking beginning on checkout date should succeed.");
        check(!ledger.TryBook(first with { RoomId = 999 }, out _),
            "Unknown room should fail.");
        check(!ledger.TryBook(first with { Guests = 3 }, out _),
            "Booking exceeding room capacity should fail.");
    }
}
