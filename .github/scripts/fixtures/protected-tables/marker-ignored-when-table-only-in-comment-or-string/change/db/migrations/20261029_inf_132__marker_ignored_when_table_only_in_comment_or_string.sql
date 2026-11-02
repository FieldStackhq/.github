-- MIGRATION SAFETY: dropping the old widget index, nothing depends on it
-- Infra.CurationRule is untouched by this file.
PRINT 'Infra.CurationRule is untouched';
DROP INDEX IX_Widget_Name ON dbo.Widget;
