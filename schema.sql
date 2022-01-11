
ROP TYPE IF EXISTS public.enum_person_role CASCADE;
CREATE TYPE public.enum_person_role AS
ENUM ('student','instructor');

DROP FUNCTION IF EXISTS get_active_rental_count;
CREATE FUNCTION get_active_rental_count(user_id integer) RETURNS TABLE(current_rental_count integer) AS
$$
SELECT COUNT(PERSON_ID) as current_rental_count
FROM RENTALS
WHERE PERSON_ID = user_id
	AND (END_DATE IS NULL OR END_DATE > CURRENT_DATE)
GROUP BY PERSON_ID
$$ LANGUAGE SQL;


CREATE TABLE public.persons (
	id serial NOT NULL,
	national_id varchar(12) NOT NULL,
	first_name varchar(50) NOT NULL,
	last_name varchar(50) NOT NULL,
	street_number varchar(10),
	street_name varchar(100) NOT NULL,
	post_code varchar(10) NOT NULL,
	role public.enum_person_role NOT NULL,
	family_id integer,
	active boolean NOT NULL,
	balance decimal NOT NULL DEFAULT 0,
	CONSTRAINT pk_persons PRIMARY KEY (id),
	CONSTRAINT uq_persons_national_id UNIQUE (national_id),
	CONSTRAINT ck_persons_no_orphans_allowed CHECK ((persons.role = 'student' AND persons.family_id IS NOT NULL) OR (persons.role = 'instructor' AND persons.family_id IS NULL))
);

COMMENT ON COLUMN public.persons.street_number IS E'Not all houses have numbers';

COMMENT ON COLUMN public.persons.family_id IS E'NULL if instructor,  students must have a family ID';

COMMENT ON COLUMN public.persons.balance IS E'Their account balance';

COMMENT ON CONSTRAINT ck_persons_no_orphans_allowed ON public.persons  IS E'We want to ensure that students all have a corresponding family ID';

CREATE TABLE public.families (
	id serial NOT NULL,
	phone_number varchar(20) NOT NULL,
	email varchar(254) NOT NULL,
	CONSTRAINT pk_families PRIMARY KEY (id)
);

DROP TYPE IF EXISTS public.enum_instrument_skill CASCADE;
CREATE TYPE public.enum_instrument_skill AS
ENUM ('beginner','intermediate','advanced');
COMMENT ON TYPE public.enum_instrument_skill IS E'Instructors are always ''advanced''';

CREATE TABLE public.skills (
	person_id integer NOT NULL,
	instrument varchar(30) NOT NULL,
	skill_level public.enum_instrument_skill NOT NULL,
	CONSTRAINT pk_skills PRIMARY KEY (person_id,instrument)
);

DROP TYPE IF EXISTS public.enum_instrument_types CASCADE;
CREATE TYPE public.enum_instrument_types AS
ENUM ('string','woodwind','brass','percussion','keyboard');

CREATE TABLE public.rental_instruments (
	id serial NOT NULL,
	instrument_type public.enum_instrument_types NOT NULL,
	brand varchar(50) NOT NULL,
	price decimal NOT NULL,
	name varchar(50) NOT NULL,
	CONSTRAINT pk_rental_instruments PRIMARY KEY (id)
);

COMMENT ON COLUMN public.rental_instruments.price IS E'Monthly rental price';

CREATE TABLE public.rentals (
	person_id integer NOT NULL,
	start_date date NOT NULL,
	end_date date NOT NULL,
	instrument_id integer NOT NULL,
	CONSTRAINT ck_rentals_rental_duration_limit CHECK (extract(month from age(rentals.end_date, rentals.start_date)) <= 12),
	CONSTRAINT pk_rentals PRIMARY KEY (person_id,instrument_id)
);

COMMENT ON CONSTRAINT ck_rentals_rental_duration_limit ON public.rentals  IS E'The rental duration must not exceed 12 months';

DROP TYPE IF EXISTS public.enum_event_type CASCADE;
CREATE TYPE public.enum_event_type AS
ENUM ('individual','ensemble','group');

CREATE TABLE public.lessons (
	id serial NOT NULL,
	occurred boolean NOT NULL,
	base_price decimal NOT NULL,
	subject varchar(20) NOT NULL,
	skill_level public.enum_instrument_skill NOT NULL,
	CONSTRAINT pk_lessons PRIMARY KEY (id)
);

COMMENT ON COLUMN public.lessons.occurred IS E'Did the lesson actually happen?';

COMMENT ON COLUMN public.lessons.subject IS E'The subject of the lesson,  either a specific instrument or a genre of music';

CREATE TABLE public.events (
	id serial NOT NULL,
	instructor_id integer NOT NULL,
	lesson_id integer NOT NULL,
	start_time timestamp NOT NULL,
	end_time timestamp NOT NULL,
	min_participants integer NOT NULL,
	max_participants integer NOT NULL,
	event_type public.enum_event_type NOT NULL,
	CONSTRAINT pk_events PRIMARY KEY (id),
	CONSTRAINT un_events_lesson_id UNIQUE (lesson_id)
);

CREATE TABLE public.event_attendance (
	event_id integer NOT NULL,
	student_id integer NOT NULL,
	CONSTRAINT pk_event_attendance PRIMARY KEY (event_id,student_id)
);

ALTER TABLE public.persons ADD CONSTRAINT fk_persons_family_id FOREIGN KEY (family_id)
REFERENCES public.families (id) MATCH SIMPLE
ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE public.skills ADD CONSTRAINT fk_skills_person_id FOREIGN KEY (person_id)
REFERENCES public.persons (id) MATCH SIMPLE
ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE public.rentals ADD CONSTRAINT fk_rentals_person_id FOREIGN KEY (person_id)
REFERENCES public.persons (id) MATCH SIMPLE
ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE public.rentals ADD CONSTRAINT fk_rentals_instrument_id FOREIGN KEY (instrument_id)
REFERENCES public.rental_instruments (id) MATCH SIMPLE
ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE public.events ADD CONSTRAINT fk_events_instructor_id FOREIGN KEY (instructor_id)
REFERENCES public.persons (id) MATCH SIMPLE
ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE public.events ADD CONSTRAINT fk_events_lesson_id FOREIGN KEY (lesson_id)
REFERENCES public.lessons (id) MATCH SIMPLE
ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE public.event_attendance ADD CONSTRAINT fk_event_attendance_student_id FOREIGN KEY (student_id)
REFERENCES public.persons (id) MATCH SIMPLE
ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE public.event_attendance ADD CONSTRAINT fk_event_attendance_event_id FOREIGN KEY (event_id)
REFERENCES public.events (id) MATCH SIMPLE
ON DELETE NO ACTION ON UPDATE NO ACTION;
