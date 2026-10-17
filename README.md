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