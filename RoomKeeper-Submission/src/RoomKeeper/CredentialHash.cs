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
