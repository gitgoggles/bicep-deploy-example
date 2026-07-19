using Microsoft.AspNetCore.Http.HttpResults;
using CoolWebApp.Components;
using CoolWebApp.Models;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddRazorComponents();

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
	app.UseExceptionHandler("/Error");
}

app.UseStaticFiles();
app.UseAntiforgery();

app.MapRazorComponents<App>();

app.MapGet("/api/products/table", () =>
{
	Product[] products =
	[
		new(1001, "Mechanical keyboard", "Peripherals", 129.00m, 14),
		new(1002, "4K monitor", "Displays", 549.99m, 7),
		new(1003, "USB-C dock", "Accessories", 189.50m, 22),
		new(1004, "Webcam", "Peripherals", 89.00m, 0),
		new(1005, "Laptop stand", "Accessories", 64.95m, 31)
	];

	return new RazorComponentResult<ProductTable>(new { Products = products });
});

app.Run();
