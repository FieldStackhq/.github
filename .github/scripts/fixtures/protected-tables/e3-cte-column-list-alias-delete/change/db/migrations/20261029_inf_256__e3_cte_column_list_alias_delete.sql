WITH stale (RuleId) AS (SELECT RuleId FROM Infra.CurationRule WHERE IsActive = 0)
DELETE st FROM stale st WHERE st.RuleId > 5;
