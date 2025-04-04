/*
This file shows Views that can make querying the data base simpler by only returning the data
needed for a specific page.

Only "venue_staff_access_tickets" view was implemented in the final product, but the others could be implemented.
*/

-- #################### VENUE ADMIN PAGES #################### --
-- Venue Admin Events Page
CREATE OR REPLACE VIEW
  venue_admins_access_events AS
SELECT
  "Events".id,
  "Events".title,
  "Events".dates,
  "Events".expect_attend,
  "Events".venue_id,
  "Venues".venue_admin_id
FROM
  "Venues"
  INNER JOIN "Events"
    ON "Events".venue_id = "Venues".id
;
-- Venue Admin Tickets Page --
CREATE OR REPLACE VIEW
  venue_admins_access_tickets AS
SELECT
  "Tickets".id AS ticket_id,
  "Tickets".service,
  "Tickets".priority,
  "Tickets".status,
  "Tickets".description,
  "Tickets".date_created,
  "Tickets".date_resolved,
  "Tickets".event_id,
  "Tickets".ticket_owner,
  "Events".title,
  "Profiles".first_name,
  "Profiles".last_name,
FROM
  "Venue"
  INNER JOIN "Events"
    ON "Events".venue_id = "Venue".id
  INNER JOIN "Tickets"
    ON "Tickets".event_id = "Events".id
  INNER JOIN "Profiles"
    ON "Profiles".id = "Tickets".ticket_owner
;


-- #################### EVENT MANAGER PAGES #################### --
-- Event Manager Events Page
CREATE OR REPLACE VIEW
  event_managers_access_events AS
SELECT
  "Events".id,
  "Events".title,
  "Events".dates,
  "Events".expect_attend,
  "Events".venue_id,
  "EventManagerEventsList".event_manager_id
FROM "Events"
  INNER JOIN "EventManagerEventsList"
    ON "EventManagerEventsList".event_id = "Events".id
;
-- Event Manager Venues Page
CREATE OR REPLACE VIEW
  event_managers_access_venues AS
SELECT
  "Venues".id,
  "Venues".name,
  "Venues".address,
  "Venues".phone,
  "Venues".venue_admin_id,
  "Venues".website,
  "Venues".total_space,
  "Venues".services,
  "EventManagerEventsList".event_manager_id
FROM
  "Venues"
  INNER JOIN "Events"
    ON "Events".venue_id = "Venues".id
  INNER JOIN "EventManagerEventsList"
    ON "EventManagerEventsList".event_id = "Events".id
    
    
    
-- #################### VENUE STAFF PAGES #################### --
-- VenueStaff Tickets Page
CREATE OR REPLACE VIEW
  venue_staff_access_tickets AS
SELECT
  "Tickets".id AS ticket_id,
  "Tickets".service,
  "Tickets".priority,
  "Tickets".status,
  "Tickets".description,
  "Tickets".date_created,
  "Tickets".date_resolved,
  "Tickets".event_id,
  "Tickets".ticket_owner,
  "Events".title,
  "Profiles".first_name,
  "Profiles".last_name,
  "VenueStaff".id AS staff_id
FROM
  "VenueStaff"
  INNER JOIN "Events"
    ON "Events".venue_id = "VenueStaff".venue_id
  INNER JOIN "Tickets"
    ON "Tickets".event_id = "Events".id
  INNER JOIN "Profiles"
    ON "Profiles".id = "Tickets".ticket_owner
;