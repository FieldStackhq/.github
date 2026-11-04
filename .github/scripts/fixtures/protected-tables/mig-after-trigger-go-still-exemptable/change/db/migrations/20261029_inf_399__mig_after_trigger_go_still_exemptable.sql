-- MIGRATION SAFETY: Infra.CurationRule -- Reviewed with Jeff, data is restored from the blob copy.
CREATE TRIGGER dbo.trgOther ON dbo.Other AFTER INSERT AS SET NOCOUNT ON;
GO
DELETE FROM Infra.CurationRule WHERE RuleId = 0;
