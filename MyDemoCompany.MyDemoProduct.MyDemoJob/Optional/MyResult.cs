namespace MyDemoCompany.MyDemoProduct.MyDemoJob;

public sealed record MyResult
{
    public required string Message { get; init; }
    public bool Succeeded { get; init; }
    public int Count { get; init; }
}