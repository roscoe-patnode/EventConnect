<script lang="ts">
  import { supabase } from '$lib/supabaseClient';
  import { onMount } from 'svelte';

  let currentUserId = "";
  // Use reactive state for events from EventManagerEventsList with joined data.
  let events = $state([]); 
  let loading = $state(true);
  let errorMsg = $state("");

  // Get the current authenticated user
  async function getCurrentUser() {
    const { data: { user }, error } = await supabase.auth.getUser();
    if (error || !user) {
      console.error("Error fetching user", error);
    } else {
      currentUserId = user.id;
    }
  }

  // Fetch events for the current event manager using EventManagerEventsList table.
  // Join with the uppercase Events table to get title, expected attendance, dates, and venue_id,
  // and join with the Venues table (using venue_id) to get the venue name.
  async function fetchMyEvents() {
    if (!currentUserId) return;
    const { data, error } = await supabase
      .from("EventManagerEventsList")
      .select(`
        event_id,
        event:Events(
          title,
          expect_attend,
          dates,
          venue_id,
          venue:Venues(name)
        )
      `)
      .eq("event_manager_id", currentUserId);
    if (error) {
      console.error("Error fetching events", error);
      errorMsg = "Error fetching events.";
    } else {
      events = data;
    }
    loading = false;
  }

  onMount(async () => {
    await getCurrentUser();
    await fetchMyEvents();
  });

  // Helper function to extract start and end dates from the dates array.
  function formatDates(dates: any): { start: string, end: string } {
    if (!dates || dates.length === 0) {
      return { start: "N/A", end: "N/A" };
    }
    const start = new Date(dates[0]).toLocaleDateString();
    const end = new Date(dates[dates.length - 1]).toLocaleDateString();
    return { start, end };
  }
</script>

<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
  <h1 class="text-3xl font-bold text-gray-900 mb-8">My Events</h1>
  
  {#if loading}
    <p>Loading events...</p>
  {:else if errorMsg}
    <p class="text-red-600">{errorMsg}</p>
  {:else if events.length === 0}
    <div class="text-center py-12 bg-gray-50 rounded-lg">
      <p class="text-gray-500">No events found.</p>
    </div>
  {:else}
    <div class="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
      {#each events as item}
        <div class="bg-white rounded-lg shadow p-6">
          <!-- Header: Event Title -->
          <div class="flex justify-between items-center mb-4">
            <h3 class="text-xl font-bold text-gray-900">
              {item.event ? item.event.title : item.event_id}
            </h3>
          </div>
          <!-- Event Details -->
          <div class="space-y-2 text-sm text-gray-600">
            <p>
              <span class="font-medium">Expected Attendance:</span>
              {item.event ? item.event.expect_attend : "N/A"}
            </p>
            {#if item.event && item.event.dates}
                <p>
                <span class="font-medium">Start Date:</span> {formatDates(item.event.dates).start}
            </p>
            <p>
                <span class="font-medium">End Date:</span> {formatDates(item.event.dates).end}
            </p>
            {/if}

            <p>
              <span class="font-medium">Venue:</span>
              {item.event && item.event.venue ? item.event.venue.name : "N/A"}
            </p>
          </div>
        </div>
      {/each}
    </div>
  {/if}
</div>
