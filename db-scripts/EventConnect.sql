/*
Things that may need to change if implemented elsewhere:
1. The schema is named "public" but may be changed.
2. The chosen identifier is Universially Unique ID (uuid) but other methods of ID can be inserted.
3. Method gen_random_uuid() is used to generate a unique ID, but other methods could be used.
4. When an array is used they can be stored as the type "text" and the data entered would be in JSON format e.g. {[1,2,3]}.
5. Text default values are not possible on some databases.
6. Enumerated type for "role" in Profiles table converted to just text.
7. Table names may need to be changed from camel-case to snake-case e.g. "EventManagerEventsList" -> "event_manager_events_list"
8. Type of "name" column in "EventSpaceSetups" may need to be changed to varchar() so it can be used as a key.

Examples of how this could be done for MySQL instead PostgreSQL can be found in the file "MySQL_EventConnect.sql"
*/


create table public."Profiles" (
  id uuid not null default gen_random_uuid (), -- Universally Unique ID or Globally Unique ID with a way to generate such ID on insertion
  first_name text not null,
  last_name text null,
  email text null,
  phone text null,
  role public.profile_roles null, -- Either 'venue_admin', 'venue_staf', or 'event_manager'
  created_at timestamp without time zone null default now(),
  updated_at timestamp without time zone null default now(),
  constraint Profiles_pkey primary key (id),
  constraint Profiles_id_fkey foreign KEY (id) references auth.users (id) on delete CASCADE -- Foreign key to *private* authentication table
);

create table public."Venues" (
  id uuid not null default gen_random_uuid (), -- Universally Unique ID or Globally Unique ID and a way to generate such ID on insertion
  address text null,
  phone text null,
  venue_admin_id uuid null, -- Universally Unique ID or Globally Unique ID
  website text null,
  total_space bigint null,
  services text[] null,
  name text null,
  constraint Venues_pkey primary key (id),
  constraint Venues_venue_admin_id_fkey foreign KEY (venue_admin_id) references "Profiles" (id) on delete set null
);

create table public."VenueStaff" (
  id uuid not null, -- Universally Unique ID or Globally Unique ID 
  service text null,
  venue_id uuid null,
  constraint VenueStaff_pkey primary key (id),
  constraint VenueStaff_id_fkey foreign KEY (id) references "Profiles" (id),
  constraint VenueStaff_venue_id_fkey foreign KEY (venue_id) references "Venues" (id)
);

create table public."Events" (
  id uuid not null default gen_random_uuid (), -- Universally Unique ID or Globally Unique ID with a way to generate such ID on insertion
  title text not null,
  dates date[] null,
  expect_attend smallint null,
  venue_id uuid null, -- Universally Unique ID or Globally Unique ID
  constraint Events_pkey primary key (id),
  constraint Events_venue_id_fkey foreign KEY (venue_id) references "Venues" (id) on delete set null
);

create table public."Tickets" (
  id uuid not null default gen_random_uuid (), -- Universally Unique ID or Globally Unique ID and a way to generate such ID on insertion
  service text null,
  priority text null default 'Medium'::text,
  status text null default 'Pending'::text,
  description text null,
  date_created timestamp with time zone not null default now(),
  date_resolved timestamp without time zone null,
  event_id uuid null, -- Universally Unique ID or Globally Unique ID
  ticket_owner uuid null, -- Universally Unique ID or Globally Unique ID
  constraint Tickets_pkey primary key (id),
  constraint Tickets_event_id_fkey foreign KEY (event_id) references "Events" (id),
  constraint Tickets_ticket_owner_fkey foreign KEY (ticket_owner) references "Profiles" (id)
);

create table public."EventSpaces" (
  id uuid not null default gen_random_uuid (), -- Universally Unique ID or Globally Unique ID with a way to generate such ID on insertion
  name text not null,
  size bigint null,
  ceilings smallint null,
  venue_id uuid null, -- Universally Unique ID or Globally Unique ID
  constraint EventSpaces_pkey primary key (id),
  constraint EventSpaces_venue_id_fkey foreign KEY (venue_id) references "Venues" (id)
);

create table public."SpaceSetups" (
  event_space_id uuid not null, -- Universally Unique ID or Globally Unique ID
  name text not null,
  capacity bigint null,
  constraint SpaceSetups_pkey primary key (event_space_id, name),
  constraint SpaceSetups_event_space_id_fkey foreign KEY (event_space_id) references "EventSpaces" (id) on delete CASCADE
);

create table public."EventManagerEventsList" (
  event_manager_id uuid not null, -- Universally Unique ID or Globally Unique ID
  event_id uuid not null, -- Universally Unique ID or Globally Unique ID
  constraint EventManagerEventsList_pkey primary key (event_manager_id, event_id),
  constraint EventManagerEventsList_event_manager_id_fkey foreign KEY (event_manager_id) references "Profiles" (id),
  constraint ProfileEventsList_event_id_fkey foreign KEY (event_id) references Events (id)
);

create table public."BookedEventSpacesList" (
  event_space_id uuid not null, -- Universally Unique ID or Globally Unique ID
  event_id uuid not null, -- Universally Unique ID or Globally Unique ID
  setup text null,
  constraint BookedEventSpacesList_pkey primary key (event_space_id, event_id),
  constraint BookedEventSpacesList_event_id_fkey foreign KEY (event_id) references "Events" (id) on delete CASCADE,
  constraint BookedEventSpacesList_event_space_id_fkey foreign KEY (event_space_id) references "EventSpaces" (id) on delete CASCADE
);