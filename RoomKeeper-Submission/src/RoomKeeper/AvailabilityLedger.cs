namespace RoomKeeper;

public sealed class AvailabilityLedger
{
    private readonly List<BookingRequest> _bookings = new();
    private readonly object _lock = new();

    public IReadOnlyList<BookingRequest> Bookings
    {
        get { lock (_lock) return _bookings.ToArray(); }
    }

    public bool TryBook(BookingRequest request, out string reason)
    {
        lock (_lock)
        {
            var room = RoomCatalog.Find(request.RoomId);

            if (room is null)
            {
                reason = "Room does not exist.";
                return false;
            }

            if (request.CheckOut <= request.CheckIn ||
                request.Guests < 1 ||
                request.Guests > room.Capacity ||
                string.IsNullOrWhiteSpace(request.GuestName))
            {
                reason = "Booking details are invalid or exceed room capacity.";
                return false;
            }

            // Half-open date ranges: checkout on a date does not overlap
            // another booking that checks in on that same date.
            bool overlaps = _bookings.Any(b =>
                b.RoomId == request.RoomId &&
                request.CheckIn < b.CheckOut &&
                b.CheckIn < request.CheckOut);

            if (overlaps)
            {
                reason = "Room is already booked for part of these dates.";
                return false;
            }

            _bookings.Add(request);
            reason = "Booking accepted.";
            return true;
        }
    }
}
