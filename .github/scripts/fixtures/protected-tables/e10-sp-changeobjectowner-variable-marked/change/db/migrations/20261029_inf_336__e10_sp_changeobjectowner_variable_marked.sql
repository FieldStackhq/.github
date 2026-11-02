-- MIGRATION SAFETY: Infra.CurationRule -- Reviewed with Jeff, data is restored from the blob copy.
DECLARE @o sysname = N'Infra.CurationRule';
EXEC sp_changeobjectowner @o, 'dbo';
