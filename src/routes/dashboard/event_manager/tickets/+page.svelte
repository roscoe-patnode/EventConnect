<script lang="ts">
  import { supabase } from '$lib/supabaseClient';
  import { onMount } from 'svelte';

  // Interfaces
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

  // Retrieve the current logged in user id
  async function getCurrentUser() {
    const { data: { user }, error } = await supabase.auth.getUser();
    if (error) {
      console.error('Error getting user:', error);
    } else if (user) {
      currentUserId = user.id;
    }
  }

  // Fetch events created by the current user from the 'events' table
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
        selectedEventId = events[0].id;
      }
    }
  }

  // Submit a new ticket using the selected event id and other details
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

<div class="container">
  <h1>Create a Service Request Ticket</h1>
  <form on:submit|preventDefault={createTicket}>
    <div class="form-group">
      <label for="event">Select Event:</label>
      <select id="event" bind:value={selectedEventId} class="form-control">
        {#each events as event}
          <option value={event.id}>{event.event_name} - {event.venue_name}</option>
        {/each}
      </select>
    </div>

    <div class="form-group">
      <label for="service">Service Type:</label>
      <input id="service" type="text" bind:value={service} placeholder="e.g., Lighting, Catering" class="form-control" required />
    </div>

    <div class="form-group">
      <label for="priority">Priority:</label>
      <select id="priority" bind:value={priority} class="form-control">
        <option value="Low">Low</option>
        <option value="Medium">Medium</option>
        <option value="High">High</option>
      </select>
    </div>

    <div class="form-group">
      <label for="description">Description:</label>
      <textarea id="description" bind:value={description} placeholder="Provide details about your service request" class="form-control"></textarea>
    </div>

    <button type="submit" class="btn">Submit Ticket</button>
  </form>
</div>

<style>
  .container {
    max-width: 800px;
    margin: 2rem auto;
    padding: 2rem;
    background-color: #ffffff;
    border-radius: 8px;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  }

  h1 {
    text-align: center;
    margin-bottom: 1.5rem;
    font-size: 2rem;
    color: #333;
  }

  .form-group {
    margin-bottom: 1.25rem;
  }

  label {
    display: block;
    margin-bottom: 0.5rem;
    font-weight: 600;
    color: #555;
  }

  .form-control {
    width: 100%;
    padding: 0.75rem;
    font-size: 1rem;
    border: 1px solid #ccc;
    border-radius: 4px;
    box-sizing: border-box;
  }

  .form-control:focus {
    outline: none;
    border-color: #007acc;
    box-shadow: 0 0 4px rgba(0, 122, 204, 0.5);
  }

  .btn {
    width: 100%;
    padding: 0.75rem;
    font-size: 1rem;
    background-color: #007acc;
    color: #fff;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    transition: background-color 0.2s ease-in-out;
  }

  .btn:hover {
    background-color: #005fa3;
  }
</style>
