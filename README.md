@'
# RoomKeeper

C# hotel booking validator and security auditor.

## Run application
dotnet run --project src/RoomKeeper

## Run tests
dotnet run --project tests/RoomKeeper.Tests

## Performance comparison
dotnet run --project src/RoomKeeper -- --perf
'@ | Set-Content -Path README.md


@'
# Software Engineering Practices

## RoomKeeper Capstone
A C# hotel booking validator and security auditor.

Features:
- Booking input validation
- Prevention of overlapping reservations
- Credential hashing demonstration
- Audit logging
- Performance comparison
- Automated test harness
'@ | Set-Content -Path README.md