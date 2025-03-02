<script lang="ts">
  import { supabase } from '$lib/supabaseClient';
  import { onMount } from 'svelte';

  // Interface for a Ticket record
  interface Ticket {
    id?: string;
    event_id: string;
    ticket_owner: string;
    service: string;
    priority: string;
    status: string;
    description: string;
    date_created: string;
    date_resolved?: string | null;
  }

  // Interface for an Event record
  interface Event {
    id: string;
    user_id: string;
    event_name: string;
    venue_name: string;
  }

  // State variables
  let currentUserId: string = '';
  let events: Event[] = [];
  let selectedEventId: string = '';
  let service = '';
  let priority = 'Medium';
  let description = '';

  // Retrieve the current user from Supabase auth
  async function getCurrentUser() {
    const { data: { user }, error } = await supabase.auth.getUser();
    if (error) {
      console.error('Error getting user:', error);
    } else if (user) {
      currentUserId = user.id;
    }
  }

  // Fetch events created by the current user
  async function fetchUserEvents() {
    if (!currentUserId) return;
    const { data, error } = await supabase
      .from('events')
      .select('*')
      .eq('user_id', currentUserId);

    if (error) {
      console.error('Error fetching events:', error);
    } else {
      events = data as Event[];
      if (events.length > 0) {
        selectedEventId = events[0].id; // Set default selection to the first event
      }
    }
  }

  // Submit a new ticket using the selected event ID and other details
  async function createTicket() {
    if (!selectedEventId) {
      alert('Please select an event.');
      return;
    }
    const newTicket: Ticket = {
      event_id: selectedEventId,
      ticket_owner: currentUserId,
      service,
      priority,
      status: 'Pending',
      description,
      date_created: new Date().toISOString()
    };

    const { data, error } = await supabase
      .from('Tickets')
      .insert([newTicket]);

    if (error) {
      console.error('Error creating ticket:', error);
      alert('Failed to create ticket. Please try again.');
    } else {
      console.log('Ticket created successfully:', data);
      alert('Ticket created!');
      // Optionally, reset form fields after submission:
      service = '';
      priority = 'Medium';
      description = '';
    }
  }

  onMount(async () => {
    await getCurrentUser();
    await fetchUserEvents();
  });
</script>

<h1>Create a Service Request Ticket</h1>

<form on:submit|preventDefault={createTicket}>
  <div>
    <label for="event">Select Event:</label>
    <select id="event" bind:value={selectedEventId}>
      {#each events as event}
        <option value={event.id}>{event.event_name} - {event.venue_name}</option>
      {/each}
    </select>
  </div>

  <div>
    <label for="service">Service Type:</label>
    <input id="service" type="text" bind:value={service} placeholder="e.g., Lighting, Catering" required />
  </div>

  <div>
    <label for="priority">Priority:</label>
    <select id="priority" bind:value={priority}>
      <option value="Low">Low</option>
      <option value="Medium">Medium</option>
      <option value="High">High</option>
    </select>
  </div>

  <div>
    <label for="description">Description:</label>
    <textarea id="description" bind:value={description} placeholder="Provide details about your service request"></textarea>
  </div>

  <button type="submit">Submit Ticket</button>
</form>
