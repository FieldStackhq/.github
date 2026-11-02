ALTER TABLE Infra.CurationRule SET (SYSTEM_VERSIONING = OFF);
ALTER TABLE Infra.CurationRule ADD Priority INT NULL;
ALTER TABLE Infra.CurationRule SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = Infra.CurationRuleHistory));
