/*
Further possible modificatiONs:
1. ID is CHAR(36) but length may vary ON implentatiON
2. Schema is named "event_cONnect" but may be different

Original implementatiON in PostgreSQL found in file "PostgreSQL_EventCONnect.sql"
*/

CREATE TABLE event_connect.Profiles (
  id CHAR(36) NOT NULL, -- Universally Unique ID or Globally Unique ID with a way to generate such ID ON insertiON
  first_name TEXT NOT NULL,
  last_name TEXT NULL,
  email TEXT NULL,
  phONe TEXT NULL,
  role TEXT NULL, -- Either 'venue_admin', 'venue_staf', or 'event_manager'
  created_at TIMESTAMP NULL DEFAULT now(),
  updated_at TIMESTAMP NULL DEFAULT now(),
  CONSTRAINT Profiles_pkey PRIMARY KEY (id)
);

CREATE TABLE event_connect.Venues (
  id CHAR(36) NOT NULL, -- Universally Unique ID or Globally Unique ID and a way to generate such ID ON insertiON
  address TEXT NULL,
  phONe TEXT NULL,
  venue_admin_id CHAR(36) NULL, -- Universally Unique ID or Globally Unique ID
  website TEXT NULL,
  total_space BIGINT NULL,
  services TEXT NULL, -- Store services as array in JSON format e.g. {[1,2,3]} or use array feature in PostgreSQL
  name TEXT NULL,
  CONSTRAINT Venues_pkey PRIMARY KEY (id),
  CONSTRAINT Venues_venue_admin_id_fkey FOREIGN KEY (venue_admin_id) REFERENCES Profiles (id) ON DELETE SET NULL
);

CREATE TABLE event_connect.VenueStaff (
  id CHAR(36) NOT NULL, -- Universally Unique ID or Globally Unique ID 
  service TEXT NULL,
  venue_id CHAR(36) NULL,
  CONSTRAINT VenueStaff_pkey PRIMARY KEY (id),
  CONSTRAINT VenueStaff_id_fkey FOREIGN KEY (id) REFERENCES Profiles (id),
  CONSTRAINT VenueStaff_venue_id_fkey FOREIGN KEY (venue_id) REFERENCES Venues (id)
);

CREATE TABLE event_connect.Events (
  id CHAR(36) NOT NULL, -- Universally Unique ID or Globally Unique ID with a way to generate such ID ON insertiON
  title TEXT NOT NULL,
  dates TEXT NULL, -- Array of dates in JSON format e.g. {[dd-mm-yyyy, dd-mm-yyyy]} or use array feature in PostgreSQL
  expect_attend SMALLINT NULL,
  venue_id CHAR(36) NULL, -- Universally Unique ID or Globally Unique ID
  CONSTRAINT Events_pkey PRIMARY KEY (id),
  CONSTRAINT Events_venue_id_fkey FOREIGN KEY (venue_id) REFERENCES Venues (id) ON DELETE SET NULL
);

CREATE TABLE event_connect.Tickets (
  id CHAR(36) NOT NULL, -- Universally Unique ID or Globally Unique ID and a way to generate such ID ON insertiON
  service TEXT NULL,
  priority TEXT NULL,
  status TEXT NULL,
  descriptiON TEXT NULL,
  date_created TIMESTAMP NOT NULL DEFAULT now(),
  date_resolved TIMESTAMP DEFAULT NULL,
  event_id CHAR(36) NULL, -- Universally Unique ID or Globally Unique ID
  ticket_owner CHAR(36) NULL, -- Universally Unique ID or Globally Unique ID
  CONSTRAINT Tickets_pkey PRIMARY KEY (id),
  CONSTRAINT Tickets_event_id_fkey FOREIGN KEY (event_id) REFERENCES Events (id),
  CONSTRAINT Tickets_ticket_owner_fkey FOREIGN KEY (ticket_owner) REFERENCES Profiles (id)
);

CREATE TABLE event_connect.EventSpaces (
  id CHAR(36) NOT NULL, -- Universally Unique ID or Globally Unique ID with a way to generate such ID ON insertiON
  name TEXT NOT NULL,
  size BIGINT NULL,
  ceilings SMALLINT NULL,
  venue_id CHAR(36) NULL, -- Universally Unique ID or Globally Unique ID
  CONSTRAINT EventSpaces_pkey PRIMARY KEY (id),
  CONSTRAINT EventSpaces_venue_id_fkey FOREIGN KEY (venue_id) REFERENCES Venues (id)
);

CREATE TABLE event_connect.SpaceSETups (
  event_space_id CHAR(36) NOT NULL, -- Universally Unique ID or Globally Unique ID
  name VARCHAR(40) NOT NULL,
  capacity BIGINT NULL,
  CONSTRAINT SpaceSETups_pkey PRIMARY KEY (event_space_id, name),
  CONSTRAINT SpaceSETups_event_space_id_fkey FOREIGN KEY (event_space_id) REFERENCES EventSpaces (id) ON DELETE CASCADE
);

CREATE TABLE event_connect.EventManagerEventsList (
  event_manager_id CHAR(36) NOT NULL, -- Universally Unique ID or Globally Unique ID
  event_id CHAR(36) NOT NULL, -- Universally Unique ID or Globally Unique ID
  CONSTRAINT EventManagerEventsList_pkey PRIMARY KEY (event_manager_id, event_id),
  CONSTRAINT EventManagerEventsList_event_manager_id_fkey FOREIGN KEY (event_manager_id) REFERENCES Profiles (id),
  CONSTRAINT ProfileEventsList_event_id_fkey FOREIGN KEY (event_id) REFERENCES Events (id)
);

CREATE TABLE event_connect.BookedEventSpacesList (
  event_space_id CHAR(36) NOT NULL, -- Universally Unique ID or Globally Unique ID
  event_id CHAR(36) NOT NULL, -- Universally Unique ID or Globally Unique ID
  SETup TEXT NULL,
  CONSTRAINT BookedEventSpacesList_pkey PRIMARY KEY (event_space_id, event_id),
  CONSTRAINT BookedEventSpacesList_event_id_fkey FOREIGN KEY (event_id) REFERENCES Events (id) ON DELETE CASCADE,
  CONSTRAINT BookedEventSpacesList_event_space_id_fkey FOREIGN KEY (event_space_id) REFERENCES EventSpaces (id) ON DELETE CASCADE
);