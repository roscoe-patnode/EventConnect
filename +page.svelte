<script lang="ts">
  import { supabase } from '$lib/supabaseClient';
  import { onMount } from 'svelte';

  let currentUserId = "";
  let events = $state([]); 
  let loading = $state(true);
  let errorMsg = $state("");
  let showModal = $state(false);
  let enteredEventId = $state("");

  async function getCurrentUser() {
    const { data: { user }, error } = await supabase.auth.getUser();
    if (error || !user) {
      console.error("Error fetching user", error);
    } else {
      currentUserId = user.id;
    }
  }

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

  async function joinEvent() {
  if (!enteredEventId || !currentUserId) {
      alert("Please enter a valid event ID.");
      return;
  }

  // Ensure enteredEventId is properly formatted
  const eventIdAsUUID = String(enteredEventId).trim().replace(/\s/g, ""); 
  
  // Check if the event exists in Events table
  const { data: eventExists, error: eventError } = await supabase
      .from("Events")
      .select("id")
      .eq("id", eventIdAsUUID) // Ensure matching type
      .maybeSingle();

  if (eventError || !eventExists) {
      alert("Event ID not found.");
      return;
  }

  // Insert into EventManagerEventsList
  const { error: insertError } = await supabase
      .from("EventManagerEventsList")
      .insert([{ event_manager_id: currentUserId, event_id: eventIdAsUUID }]);

  console.log("Insert Error (if any):", insertError);

  if (insertError) {
      alert("Error joining event.");
      console.error("Insert error:", insertError);
  } else {
      alert("Successfully joined the event!");
      showModal = false;

      // Reload events to update the list
      await fetchMyEvents();
  }
}




  onMount(async () => {
    await getCurrentUser();
    await fetchMyEvents();
  });

  function openModal() {
    showModal = true;
  }

  function closeModal() {
    showModal = false;
  }
</script>

<!-- Main Content -->
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
          <div class="flex justify-between items-center mb-4">
            <h3 class="text-xl font-bold text-gray-900">
              {item.event ? item.event.title : item.event_id}
            </h3>
          </div>
          <div class="space-y-2 text-sm text-gray-600">
            <p><span class="font-medium">Expected Attendance:</span> {item.event ? item.event.expect_attend : "N/A"}</p>
            {#if item.event && item.event.dates}
              <p><span class="font-medium">Start Date:</span> {new Date(item.event.dates[0]).toLocaleDateString()}</p>
              <p><span class="font-medium">End Date:</span> {new Date(item.event.dates[item.event.dates.length - 1]).toLocaleDateString()}</p>
            {/if}
            <p><span class="font-medium">Venue:</span> {item.event && item.event.venue ? item.event.venue.name : "N/A"}</p>
          </div>
        </div>
      {/each}
    </div>
  {/if}

  <!-- Join Event Button -->
  <div class="flex justify-center mt-8">
    <button class="bg-blue-600 text-white font-bold py-3 px-6 rounded-lg shadow hover:bg-blue-700 transition" on:click={openModal}>
      Join Event
    </button>
  </div>
</div>

<!-- Modal for Joining Event -->
{#if showModal}
  <div class="fixed inset-0 flex items-center justify-center bg-black bg-opacity-50">
    <div class="bg-white p-6 rounded-lg shadow-lg w-96">
      <h2 class="text-lg font-bold mb-4">Enter Event ID</h2>
      <input
        type="text"
        bind:value={enteredEventId}
        class="w-full p-2 border border-gray-300 rounded mb-4"
        placeholder="Enter event ID..."
      />
      <div class="flex justify-end space-x-2">
        <button class="bg-gray-500 text-white py-2 px-4 rounded hover:bg-gray-600" on:click={closeModal}>Cancel</button>
        <button class="bg-blue-600 text-white py-2 px-4 rounded hover:bg-blue-700" on:click={joinEvent}>Join</button>
      </div>
    </div>
  </div>
{/if}
