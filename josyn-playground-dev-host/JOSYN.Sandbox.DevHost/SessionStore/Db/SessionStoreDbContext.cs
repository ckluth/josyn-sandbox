using Microsoft.EntityFrameworkCore;

namespace JOSYN.Sandbox.DevHost;

internal sealed class SessionStoreDbContext(string connectionString) : DbContext
{
    public DbSet<SessionStoreEntity> SessionStore => Set<SessionStoreEntity>();

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        => optionsBuilder.UseSqlServer(connectionString, o => o.EnableRetryOnFailure());

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<SessionStoreEntity>(e =>
        {
            e.ToTable("SessionStore", "josyn");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedOnAdd();
            e.Property(x => x.UID).IsRequired();
            e.Property(x => x.JobTypeName).IsRequired().HasMaxLength(256);
            e.Property(x => x.Arguments).IsRequired();
            e.Property(x => x.Result).IsRequired();
        });
    }
}
