namespace RoomKeeper;

public sealed class BookingDesk
{
    private readonly AvailabilityLedger _ledger;
    private readonly AuditLog _audit;

    public BookingDesk(AvailabilityLedger ledger, AuditLog audit)
    {
        _ledger = ledger;
        _audit = audit;
    }

    public bool Submit(BookingRequest request, out string message)
    {
        bool accepted = _ledger.TryBook(request, out message);
        _audit.Record(accepted ? "BOOKING_ACCEPTED" : "BOOKING_REJECTED",
            $"Guest={request.GuestName}; Room={request.RoomId}; " +
            $"CheckIn={request.CheckIn:yyyy-MM-dd}; CheckOut={request.CheckOut:yyyy-MM-dd}; " +
            $"Reason={message}");

        return accepted;
    }
}
