using RoomKeeper;

namespace RoomKeeper.Tests;

public static class ParserTests
{
    public static void Run(Action<bool, string> check)
    {
        check(BookingParser.TryParse("Alex|101|2026-11-01|2026-11-03|2",
            out var request, out _), "Valid booking should parse.");
        check(request?.RoomId == 101, "Parsed room ID should match.");
        check(!BookingParser.TryParse("bad input", out _, out _),
            "Malformed booking should be rejected.");
        check(!BookingParser.TryParse("Alex|101|2026-11-03|2026-11-01|2",
            out _, out _), "Checkout before check-in should be rejected.");
    }
}
