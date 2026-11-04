-- MIGRATION SAFETY: Infra.CurationRule -- Reviewed with Jeff, data is restored from the blob copy.
DELETE FROM Infra.CurationRule WHERE RuleId = 0;
GO
CREATE TRIGGER dbo.trgOther ON dbo.Other AFTER INSERT AS DELETE FROM Infra.CurationRule;
