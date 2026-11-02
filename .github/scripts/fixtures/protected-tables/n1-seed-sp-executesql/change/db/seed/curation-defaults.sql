DECLARE @sql nvarchar(max) = N'DELETE FROM x';
EXEC sp_executesql @sql;
