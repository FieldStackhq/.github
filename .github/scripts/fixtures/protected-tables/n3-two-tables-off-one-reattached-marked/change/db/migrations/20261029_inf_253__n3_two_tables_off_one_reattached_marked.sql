-- MIGRATION SAFETY: Infra.CurationRule, Infra.Other -- Reviewed with Jeff, data is restored from the blob copy.
ALTER TABLE Infra.CurationRule SET (SYSTEM_VERSIONING = OFF);
ALTER TABLE Infra.Other SET (SYSTEM_VERSIONING = OFF);
ALTER TABLE Infra.CurationRule SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = Infra.CurationRuleHistory));
