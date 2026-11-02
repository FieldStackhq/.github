-- MIGRATION SAFETY: Infra.CurationRule -- Reviewed with Jeff, data is restored from the blob copy.
DELETE FROM Infra.CurationRule WHERE IsActive = 0;
DELETE FROM Infra.CurationRuleHistory WHERE ValidTo < '2020-01-01';
