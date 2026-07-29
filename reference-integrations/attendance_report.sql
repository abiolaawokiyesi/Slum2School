-- S2S Attendance — per-office report (last 7 days)
--
-- (A) Original event-log shape (one row per IN/OUT event):
--     table attendance_logs(staff_id, timestamp, type ['IN'|'OUT'], office_id, lat, lng)
SELECT
    DATE(timestamp)                                   AS log_date,
    office_id,
    COUNT(DISTINCT staff_id)                          AS total_staff_present,
    COUNT(CASE WHEN type = 'IN'  THEN 1 END)          AS total_clock_ins,
    COUNT(CASE WHEN type = 'OUT' THEN 1 END)          AS total_clock_outs
FROM attendance_logs
WHERE timestamp >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY log_date, office_id
ORDER BY log_date DESC, office_id;

-- (B) Same report against the S2S People Portal schema (one row per staff per day,
--     with clock_in / clock_out timestamps). This is shipped as the view
--     public.v_attendance_last7_by_office in supabase/03_views.sql:
SELECT
    work_date                                          AS log_date,
    COALESCE(location_id, 'unspecified')               AS office_id,
    COALESCE(location_name, 'Unspecified')             AS office,
    COUNT(DISTINCT email)                              AS total_staff_present,
    COUNT(*) FILTER (WHERE clock_in  IS NOT NULL)      AS total_clock_ins,
    COUNT(*) FILTER (WHERE clock_out IS NOT NULL)      AS total_clock_outs
FROM public.attendance
WHERE work_date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY work_date, location_id, location_name
ORDER BY log_date DESC, office_id;
