namespace MyDemoCompany.MyDemoProduct.MyDemoJob;


// Wird unterstützt; aber lass es lieber....
public enum MyEnum
{
    Value1,
    Value2,
    Value3
}

public sealed record MyArguments
{
    public required string Msg { get; init; }
    public int Count { get; init; }
    public int? MaybeCount { get; init; }
    public bool IsSpecial { get; init; }
    public DateOnly OnlyDate { get; init; }
    public DateTime Expired { get; init; }
    public DateTime? MaybeDateTime { get; init; }
    public MyEnum EnumValue { get; init; }
    public TimeSpan MyTimeSpan { get; set; }
    public decimal Price { get; set; }
}