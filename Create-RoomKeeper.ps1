$ErrorActionPreference = "Stop"

$root = "RoomKeeper"
New-Item -ItemType Directory -Force -Path "$root/src/RoomKeeper","$root/tests/RoomKeeper.Tests" | Out-Null

function Write-ProjectFile($path, $content) {
    $fullPath = Join-Path $root $path
    $directory = Split-Path $fullPath
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
    Set-Content -Path $fullPath -Value $content -Encoding utf8
}

Write-ProjectFile "src/RoomKeeper/RoomKeeper.csproj" @'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net8.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>
</Project>
'@

Write-ProjectFile "src/RoomKeeper/RoomCatalog.cs" @'
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
'@

Write-ProjectFile "src/RoomKeeper/BookingRequest.cs" @'
namespace RoomKeeper;

public sealed record BookingRequest(
    string GuestName,
    int RoomId,
    DateOnly CheckIn,
    DateOnly CheckOut,
    int Guests);
'@

Write-ProjectFile "src/RoomKeeper/BookingParser.cs" @'
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
'@

Write-ProjectFile "src/RoomKeeper/AvailabilityLedger.cs" @'
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
'@

Write-ProjectFile "src/RoomKeeper/CredentialHash.cs" @'
using System.Security.Cryptography;

namespace RoomKeeper;

public static class CredentialHash
{
    // SHA-256 is included for the requested demonstration only.
    // For real account passwords, use Argon2id, scrypt, or PBKDF2
    // with a unique salt and an appropriate work factor.
    public static string Hash(string password)
    {
        ArgumentNullException.ThrowIfNull(password);
        byte[] bytes = System.Text.Encoding.UTF8.GetBytes(password);
        return Convert.ToHexString(SHA256.HashData(bytes));
    }

    public static bool Verify(string password, string expectedHash)
    {
        if (string.IsNullOrEmpty(expectedHash))
            return false;

        try
        {
            byte[] actual = Convert.FromHexString(Hash(password));
            byte[] expected = Convert.FromHexString(expectedHash);

            return actual.Length == expected.Length &&
                   CryptographicOperations.FixedTimeEquals(actual, expected);
        }
        catch (FormatException)
        {
            return false;
        }
    }
}
'@

Write-ProjectFile "src/RoomKeeper/AuditLog.cs" @'
namespace RoomKeeper;

public sealed class AuditLog
{
    private readonly string _path;
    private readonly object _lock = new();

    public AuditLog(string path) => _path = path;

    public void Record(string action, string details)
    {
        string line = $"{DateTimeOffset.UtcNow:O}\t{Clean(action)}\t{Clean(details)}";
        lock (_lock)
        {
            string? directory = Path.GetDirectoryName(_path);
            if (!string.IsNullOrEmpty(directory))
                Directory.CreateDirectory(directory);

            File.AppendAllText(_path, line + Environment.NewLine);
        }
    }

    private static string Clean(string value) =>
        value.Replace('\r', ' ').Replace('\n', ' ').Replace('\t', ' ');
}
'@

Write-ProjectFile "src/RoomKeeper/PerfComparison.cs" @'
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
'@

Write-ProjectFile "src/RoomKeeper/BookingDesk.cs" @'
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
'@

Write-ProjectFile "src/RoomKeeper/Program.cs" @'
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
'@

Write-ProjectFile "tests/RoomKeeper.Tests/RoomKeeper.Tests.csproj" @'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net8.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>
  <ItemGroup>
    <ProjectReference Include="../../src/RoomKeeper/RoomKeeper.csproj" />
  </ItemGroup>
</Project>
'@

Write-ProjectFile "tests/RoomKeeper.Tests/ParserTests.cs" @'
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
'@

Write-ProjectFile "tests/RoomKeeper.Tests/CheckTests.cs" @'
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
'@

Write-ProjectFile "tests/RoomKeeper.Tests/SupportTests.cs" @'
using RoomKeeper;

namespace RoomKeeper.Tests;

public static class SupportTests
{
    public static void Run(Action<bool, string> check)
    {
        string hash = CredentialHash.Hash("Example-Password-123!");
        check(CredentialHash.Verify("Example-Password-123!", hash),
            "Correct password should verify.");
        check(!CredentialHash.Verify("Wrong-Password", hash),
            "Incorrect password should fail verification.");
        check(hash.Length == 64, "SHA-256 hex output should be 64 characters.");
    }
}
'@

Write-ProjectFile "tests/RoomKeeper.Tests/DeskTests.cs" @'
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
'@

Write-ProjectFile "tests/RoomKeeper.Tests/Program.cs" @'
namespace RoomKeeper.Tests;

internal static class Program
{
    private static int _passed;
    private static int _failed;

    private static void Check(bool condition, string message)
    {
        if (condition)
        {
            _passed++;
            Console.WriteLine($"PASS: {message}");
        }
        else
        {
            _failed++;
            Console.WriteLine($"FAIL: {message}");
        }
    }

    private static void Main()
    {
        ParserTests.Run(Check);
        CheckTests.Run(Check);
        SupportTests.Run(Check);
        DeskTests.Run(Check);

        Console.WriteLine($"\nPassed: {_passed}; Failed: {_failed}");
        if (_failed > 0)
            Environment.ExitCode = 1;
    }
}
'@

Write-ProjectFile "bookings.txt" @'
Alex|101|2026-11-01|2026-11-03|2
Sam|102|2026-11-04|2026-11-06|2
Jordan|103|2026-11-10|2026-11-12|3
'@

Write-ProjectFile ".gitignore" @'
bin/
obj/
.vs/
audit.log
'@

Write-Host "`nRoomKeeper project files created in: $root" -ForegroundColor Green
Write-Host "Next: cd RoomKeeper" -ForegroundColor Cyan
Write-Host "Run the application:" -ForegroundColor Cyan
Write-Host "dotnet run --project src/RoomKeeper" -ForegroundColor Yellow
Write-Host "Run the test harness:" -ForegroundColor Cyan
Write-Host "dotnet run --project tests/RoomKeeper.Tests" -ForegroundColor Yellow
Write-Host "Run performance comparison:" -ForegroundColor Cyan
Write-Host "dotnet run --project src/RoomKeeper -- --perf" -ForegroundColor Yellow