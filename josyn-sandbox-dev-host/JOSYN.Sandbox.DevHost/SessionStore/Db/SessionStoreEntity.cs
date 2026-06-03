namespace JOSYN.Sandbox.DevHost;

internal sealed class SessionStoreEntity
{
    public int Id { get; set; }
    public Guid UID { get; set; }
    public string JobTypeName { get; set; } = string.Empty;

    // ReSharper disable once EntityFramework.ModelValidation.UnlimitedStringLength
    // Arguments can be large, so we won't set a max length.
    public string Arguments { get; set; } = string.Empty;

    // ReSharper disable once EntityFramework.ModelValidation.UnlimitedStringLength
    // Result can also be large, so we won't set a max length.
    public string Result { get; set; } = string.Empty;
}
