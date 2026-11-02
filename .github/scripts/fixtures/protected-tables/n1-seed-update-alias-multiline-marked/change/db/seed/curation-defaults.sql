-- MIGRATION SAFETY: Infra.CurationRule -- Reviewed with Jeff, data is restored from the blob copy.
UPDATE r
SET r.Note = N'seeded'
FROM Infra.CurationRule r
WHERE r.RuleId = 1;
