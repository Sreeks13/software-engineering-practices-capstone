namespace RoomKeeper;

public static class BookingParser
{
    // Format: guest|roomId|yyyy-MM-dd|yyyy-MM-dd|guests
    public static bool TryParse(string line, out BookingRequest? request, out string error)
    {
        request = null;
        error = "";

        string[] parts = line.Split('|');
        if (parts.Length != 5)
        {
            error = "Expected five fields separated by '|'.";
            return false;
        }

        if (string.IsNullOrWhiteSpace(parts[0]))
        {
            error = "Guest name is required.";
            return false;
        }

        if (!int.TryParse(parts[1], out int roomId) ||
            !DateOnly.TryParseExact(parts[2], "yyyy-MM-dd", out var checkIn) ||
            !DateOnly.TryParseExact(parts[3], "yyyy-MM-dd", out var checkOut) ||
            !int.TryParse(parts[4], out int guests))
        {
            error = "Invalid room, date, or guest count.";
            return false;
        }

        if (checkOut <= checkIn)
        {
            error = "Check-out must be after check-in.";
            return false;
        }

        if (guests < 1)
        {
            error = "Guest count must be positive.";
            return false;
        }

        request = new BookingRequest(parts[0].Trim(), roomId, checkIn, checkOut, guests);
        return true;
    }
}
