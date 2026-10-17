namespace RoomKeeper;

public sealed record BookingRequest(
    string GuestName,
    int RoomId,
    DateOnly CheckIn,
    DateOnly CheckOut,
    int Guests);
