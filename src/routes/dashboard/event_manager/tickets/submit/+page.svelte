<script lang="ts">
    import { supabase } from '$lib/supabaseClient';
    import { onMount } from 'svelte';
    import { goto } from '$app/navigation';
  
    // Define interfaces for type safety
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
  
    // Interface for events pulled from the EventManagerEventsList join
    interface ManagerEvent {
      event_id: string;
      event: {
        title: string;
      };
    }
  
    let events: ManagerEvent[] = [];
    let selectedEventId = '';
    let service = '';
    let priority = 'Medium';
    let description = '';
  
    let currentUserId = '';
  
    // Get the current user
    async function getCurrentUser() {
      const { data: { user }, error } = await supabase.auth.getUser();
      if (error) {
        console.error('Error getting user:', error);
      } else if (user) {
        currentUserId = user.id;
      }
    }
  
    // Fetch events for the current user from the EventManagerEventsList table,
    // joining with the uppercase "Events" table to get the event title.
    async function fetchUserEvents() {
      if (!currentUserId) return;
      const { data, error } = await supabase
        .from('EventManagerEventsList')
        .select('event_id, event:Events(title)')
        .eq('event_manager_id', currentUserId);
  
      if (error) {
        console.error('Error fetching manager events:', error);
      } else {
        events = data as ManagerEvent[];
        if (events.length > 0) {
          selectedEventId = events[0].event_id;
        }
      }
    }
  
    // Create a new ticket and then redirect to the tickets page.
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
        alert('Failed to create ticket.');
      } else {
        console.log('Ticket created successfully:', data);
        alert('Ticket created!');
        // Redirect to the previous tickets page
        goto('/dashboard/event_manager/tickets');
      }
    }
  
    onMount(async () => {
      await getCurrentUser();
      await fetchUserEvents();
    });
  </script>
  
  <div class="max-w-7xl mx-auto px-4 py-8">
    <h1 class="text-3xl font-bold text-gray-900 mb-8">Submit a Service Request</h1>
    <form on:submit|preventDefault={createTicket} class="space-y-6">
      <div>
        <label for="event" class="block text-sm font-medium text-gray-700">Select Event:</label>
        <select
          id="event"
          bind:value={selectedEventId}
          class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
        >
          {#each events as managerEvent}
            <option value={managerEvent.event_id}>{managerEvent.event.title}</option>
          {/each}
        </select>
      </div>
  
      <div>
        <label for="service" class="block text-sm font-medium text-gray-700">Service Type:</label>
        <input
          id="service"
          type="text"
          bind:value={service}
          placeholder="e.g., Lighting, Catering"
          required
          class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
        />
      </div>
  
      <div>
        <label for="priority" class="block text-sm font-medium text-gray-700">Priority:</label>
        <select
          id="priority"
          bind:value={priority}
          class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
        >
          <option value="Low">Low</option>
          <option value="Medium">Medium</option>
          <option value="High">High</option>
        </select>
      </div>
  
      <div>
        <label for="description" class="block text-sm font-medium text-gray-700">Description:</label>
        <textarea
          id="description"
          bind:value={description}
          placeholder="Provide details about your service request"
          class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
        ></textarea>
      </div>
  
      <button
        type="submit"
        class="w-full px-4 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
      >
        Submit Ticket
      </button>
    </form>
  </div>
  
