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
