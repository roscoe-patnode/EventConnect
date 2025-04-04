/*
Things that may need to change if implemented elsewhere:
1. The schema is named "public" but may be changed.
2. The chosen identifier is Universially Unique ID (uuid) but other methods of ID can be inserted.
3. Method gen_random_uuid() is used to generate a unique ID, but other methods could be used.
4. When an array is used they can be stored as the type "TEXT" and the data entered would be in JSON format e.g. {[1,2,3]}.
5. TEXT DEFAULT values are NOT possible on some databases.
6. Enumerated type for "role" in Profiles table converted to just TEXT.
7. Table names may need to be changed from camel-case to snake-case e.g. "EventManagerEventsList" -> "event_manager_events_list"
8. Type of "name" column in "EventSpaceSetups" may need to be changed to varchar() so it can be used as a key.

Examples of how this could be done for MySQL instead PostgreSQL can be found in the file "MySQL_EventConnect.sql"
*/


CREATE TABLE public."Profiles" (
  id uuid NOT NULL DEFAULT gen_random_uuid (), -- Universally Unique ID or Globally Unique ID with a way to generate such ID on insertion
  first_name TEXT NOT NULL,
  last_name TEXT NULL,
  email TEXT NULL,
  phone TEXT NULL,
  role public.profile_roles NULL, -- Either 'venue_admin', 'venue_staf', or 'event_manager'
  created_at TIMESTAMP WITHOUT TIME zone NULL DEFAULT now(),
  updated_at TIMESTAMP WITHOUT TIME zone NULL DEFAULT now(),
  CONSTRAINT Profiles_pkey PRIMARY KEY (id),
  CONSTRAINT Profiles_id_fkey FOREIGN KEY (id) references auth.users (id) ON DELETE CASCADE -- FOREIGN KEY to *private* authentication table
);

CREATE TABLE public."Venues" (
  id uuid NOT NULL DEFAULT gen_random_uuid (), -- Universally Unique ID or Globally Unique ID and a way to generate such ID on insertion
  address TEXT NULL,
  phone TEXT NULL,
  venue_admin_id uuid NULL, -- Universally Unique ID or Globally Unique ID
  website TEXT NULL,
  total_space bigint NULL,
  services TEXT[] NULL,
  name TEXT NULL,
  CONSTRAINT Venues_pkey PRIMARY KEY (id),
  CONSTRAINT Venues_venue_admin_id_fkey FOREIGN KEY (venue_admin_id) references "Profiles" (id) ON DELETE set NULL
);

CREATE TABLE public."VenueStaff" (
  id uuid NOT NULL, -- Universally Unique ID or Globally Unique ID 
  service TEXT NULL,
  venue_id uuid NULL,
  CONSTRAINT VenueStaff_pkey PRIMARY KEY (id),
  CONSTRAINT VenueStaff_id_fkey FOREIGN KEY (id) references "Profiles" (id),
  CONSTRAINT VenueStaff_venue_id_fkey FOREIGN KEY (venue_id) references "Venues" (id)
);

CREATE TABLE public."Events" (
  id uuid NOT NULL DEFAULT gen_random_uuid (), -- Universally Unique ID or Globally Unique ID with a way to generate such ID on insertion
  title TEXT NOT NULL,
  dates date[] NULL,
  expect_attend smallint NULL,
  venue_id uuid NULL, -- Universally Unique ID or Globally Unique ID
  CONSTRAINT Events_pkey PRIMARY KEY (id),
  CONSTRAINT Events_venue_id_fkey FOREIGN KEY (venue_id) references "Venues" (id) ON DELETE set NULL
);

CREATE TABLE public."Tickets" (
  id uuid NOT NULL DEFAULT gen_random_uuid (), -- Universally Unique ID or Globally Unique ID and a way to generate such ID on insertion
  service TEXT NULL,
  priority TEXT NULL DEFAULT 'Medium'::TEXT,
  status TEXT NULL DEFAULT 'Pending'::TEXT,
  description TEXT NULL,
  date_created timestamp with time zone NOT NULL DEFAULT now(),
  date_resolved TIMESTAMP WITHOUT TIME zone NULL,
  event_id uuid NULL, -- Universally Unique ID or Globally Unique ID
  ticket_owner uuid NULL, -- Universally Unique ID or Globally Unique ID
  CONSTRAINT Tickets_pkey PRIMARY KEY (id),
  CONSTRAINT Tickets_event_id_fkey FOREIGN KEY (event_id) references "Events" (id),
  CONSTRAINT Tickets_ticket_owner_fkey FOREIGN KEY (ticket_owner) references "Profiles" (id)
);

CREATE TABLE public."EventSpaces" (
  id uuid NOT NULL DEFAULT gen_random_uuid (), -- Universally Unique ID or Globally Unique ID with a way to generate such ID on insertion
  name TEXT NOT NULL,
  size bigint NULL,
  ceilings smallint NULL,
  venue_id uuid NULL, -- Universally Unique ID or Globally Unique ID
  CONSTRAINT EventSpaces_pkey PRIMARY KEY (id),
  CONSTRAINT EventSpaces_venue_id_fkey FOREIGN KEY (venue_id) references "Venues" (id)
);

CREATE TABLE public."SpaceSetups" (
  event_space_id uuid NOT NULL, -- Universally Unique ID or Globally Unique ID
  name TEXT NOT NULL,
  capacity bigint NULL,
  CONSTRAINT SpaceSetups_pkey PRIMARY KEY (event_space_id, name),
  CONSTRAINT SpaceSetups_event_space_id_fkey FOREIGN KEY (event_space_id) references "EventSpaces" (id) ON DELETE CASCADE
);

CREATE TABLE public."EventManagerEventsList" (
  event_manager_id uuid NOT NULL, -- Universally Unique ID or Globally Unique ID
  event_id uuid NOT NULL, -- Universally Unique ID or Globally Unique ID
  CONSTRAINT EventManagerEventsList_pkey PRIMARY KEY (event_manager_id, event_id),
  CONSTRAINT EventManagerEventsList_event_manager_id_fkey FOREIGN KEY (event_manager_id) references "Profiles" (id),
  CONSTRAINT ProfileEventsList_event_id_fkey FOREIGN KEY (event_id) references Events (id)
);

CREATE TABLE public."BookedEventSpacesList" (
  event_space_id uuid NOT NULL, -- Universally Unique ID or Globally Unique ID
  event_id uuid NOT NULL, -- Universally Unique ID or Globally Unique ID
  setup TEXT NULL,
  CONSTRAINT BookedEventSpacesList_pkey PRIMARY KEY (event_space_id, event_id),
  CONSTRAINT BookedEventSpacesList_event_id_fkey FOREIGN KEY (event_id) references "Events" (id) ON DELETE CASCADE,
  CONSTRAINT BookedEventSpacesList_event_space_id_fkey FOREIGN KEY (event_space_id) references "EventSpaces" (id) ON DELETE CASCADE
);