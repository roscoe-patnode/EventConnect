<script lang="ts">
    import { supabase } from '$lib/supabaseClient';
    import { onMount } from 'svelte';
    import { goto } from '$app/navigation';
  
    let loading = true;
    let userRole = "";

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
        venue_id: string; // assumed to be present so we can lookup the venue
      };
    }
  
    let events: ManagerEvent[] = [];
    let selectedEventId = '';
    let service = '';
    let priority = 'Medium';
    let description = '';
  
    // Reactive array for service options from the venue
    let serviceOptions: string[] = [];
  
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
    // joining with the uppercase "Events" table to get the event title and venue_id.
    async function fetchUserEvents() {
      if (!currentUserId) return;
      const { data, error } = await supabase
        .from('EventManagerEventsList')
        .select('event_id, event:Events(title, venue_id)')
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
  
    // When the selected event changes, fetch the corresponding services from the venue.
    async function fetchServicesForEvent(eventId: string) {
      // Find the event record from our events array.
      const managerEvent = events.find(e => e.event_id === eventId);
      if (!managerEvent) {
        serviceOptions = [];
        return;
      }
      const venueId = managerEvent.event.venue_id;
      // Query the Venues table for the services array.
      const { data, error } = await supabase
        .from('Venues')
        .select('services')
        .eq('id', venueId)
        .single();
  
      if (error) {
        console.error('Error fetching venue services:', error);
        serviceOptions = [];
      } else {
        // Assuming data.services is a text[] column.
        serviceOptions = data.services || [];
        // If there are options, set service to the first one (or clear if needed)
        if (serviceOptions.length > 0 && !service) {
          service = serviceOptions[0];
        }
      }
    }
  
    // Reactive block: When selectedEventId changes, fetch its service options.
    $: if (selectedEventId) {
      fetchServicesForEvent(selectedEventId);
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
        // Optionally, reset form fields
        service = '';
        priority = 'Medium';
        description = '';
        // Redirect to the tickets page after creation
        goto('/dashboard/event_manager/tickets');
      }
    }
    async function fetchRole() {
        const { data: userData } = await supabase.auth.getUser();
        const { data: userRoleData, error } = await supabase
            .from("Profiles")
            .select("role")
            .eq("id", userData.user!.id);
        if (error) throw error;
            userRole = userRoleData[0].role;
    }

    $: onMount(async () => {
      await getCurrentUser();
      await fetchUserEvents();
      await fetchRole();
      loading = false;
    });
  </script>
  <!-- Check if User has the Permissions to view page -->
{#if userRole !== 'event_manager' && !loading}
<div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4">
    <div class="fixed inset-0 bg-gray-900 bg-opacity-80 flex items-center justify-center p-6">
        <div class="bg-white rounded-2xl shadow-xl p-6 max-w-md text-center">
            <h2 class="text-2xl font-semibold text-gray-800">Access Denied</h2>
            <p class="text-gray-600 mt-2">You do not have permission to view this page.</p>
        </div>
    </div>
</div>
{:else}
  <div class="max-w-2xl mx-auto px-4 py-8">
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
        <!-- Instead of a text input, use a dropdown populated with options from the venue's services -->
        <select
          id="service"
          bind:value={service}
          class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
        >
          {#if serviceOptions.length > 0}
            {#each serviceOptions as option}
              <option value={option}>{option}</option>
            {/each}
          {:else}
            <option value="">No services available</option>
          {/if}
        </select>
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
{/if}
