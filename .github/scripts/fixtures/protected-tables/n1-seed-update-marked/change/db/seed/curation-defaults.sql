-- MIGRATION SAFETY: Infra.CurationRule -- Reviewed with Jeff, data is restored from the blob copy.
UPDATE Infra.CurationRule SET Note = N'seeded' WHERE RuleId = 1;
