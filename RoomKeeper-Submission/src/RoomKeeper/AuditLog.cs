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
