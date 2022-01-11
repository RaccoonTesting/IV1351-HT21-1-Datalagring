SELECT COUNT(id) FROM events
WHERE start_time >= '2019-01-01'
AND start_time < '2019-02-01';

SELECT COUNT(id) FROM events
WHERE start_time >= '2019-01-01'
AND start_time < '2019-02-01' AND event_type = 'individual';

SELECT COUNT(id) FROM events
WHERE start_time >= '2019-01-01'
AND start_time < '2019-02-01' AND event_type = 'group';

SELECT COUNT(id) FROM events
WHERE start_time >= '2019-01-01'
AND start_time < '2019-02-01' AND event_type = 'ensemble';




SELECT SUM(monthly)/12 FROM (SELECT DATE_TRUNC('month',start_time) m,
COUNT(id) AS monthly
FROM events
GROUP BY m
ORDER BY m) sub
WHERE m >= '2019-01-01'
AND m < '2020-01-01';

SELECT * FROM (
SELECT COUNT(*) as numlessons, instructor_id FROM events
WHERE start_time >= date_trunc('month', CURRENT_DATE)
GROUP BY instructor_id
ORDER BY numlessons ASC
)as sub
WHERE sub.numlessons <= 2

SELECT lessons.subject, events.max_participants, events.min_participants, extract(isodow from events.start_time) as dayofweek FROM events
INNER JOIN lessons on lessons.id= events.lesson_id
WHERE start_time >= '2019-01-01'
AND start_time < '2019-02-01'

GROUP BY extract(isodow from events.start_time), lessons.subject, events.max_participants, events.min_participants


SELECT
event_id,
CASE
      WHEN  max_participants <= booked THEN 'full'
      WHEN  (max_participants - booked)<= 2 THEN '1 or 2 spots left '
      WHEN  (max_participants - booked)> 2 THEN 'more than 2 spots left '
END FROM(
SELECT
count(*) as booked, event_attendance.event_id, events.max_participants
FROM event_attendance
INNER JOIN events on event_attendance.event_id = events.id
GROUP BY (event_attendance.event_id, events.max_participants)) as t1
