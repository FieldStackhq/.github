DECLARE @old NVARCHAR(400) = N'dbo.Widget.Name';
EXEC sp_rename @old, N'Label', N'COLUMN';
