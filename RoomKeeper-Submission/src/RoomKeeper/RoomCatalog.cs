namespace RoomKeeper;

public sealed record Room(int Id, string Name, int Capacity);

public static class RoomCatalog
{
    public static IReadOnlyList<Room> Rooms { get; } = new[]
    {
        new Room(101, "Standard", 2),
        new Room(102, "Deluxe", 3),
        new Room(103, "Suite", 4)
    };

    public static Room? Find(int id) => Rooms.FirstOrDefault(r => r.Id == id);
}
