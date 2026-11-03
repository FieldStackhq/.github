-- MIGRATION SAFETY: Infra.CurationRule -- Reviewed with Jeff, data is restored from the blob copy.
CREATE OR ALTER PROC dbo.W AS DELETE FROM Infra.CurationRule WHERE RuleId = 0;
GO
EXEC dbo.W;
