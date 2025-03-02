<script lang="ts">
  import { supabase } from '$lib/supabaseClient';
  import { onMount } from 'svelte';

  // Define the interface for a Ticket record, including joined event and profile data.
  interface Ticket {
    id: string;
    event_id: string;
    ticket_owner: string;
    service: string;
    priority: string;
    status: string;
    description: string;
    date_created: string;
    date_resolved?: string | null;
    event?: {
      event_name: string;
    };
    Profiles?: {
      first_name: string;
      last_name: string;
    };
  }

  let tickets: Ticket[] = [];
  let loading = true;
  let errorMsg = '';

  // Fetch tickets, joining the events table and the Profiles table for the ticket owner's name.
  async function fetchTickets() {
    loading = true;
    const { data, error } = await supabase
      .from('Tickets')
      .select('*, event:events (event_name), Profiles (first_name, last_name)');

    console.log('Fetched tickets:', data, 'Error:', error);

    if (error) {
      console.error('Error fetching tickets:', error);
      errorMsg = 'Error fetching tickets. Please try again later.';
    } else {
      tickets = data as Ticket[];
      errorMsg = '';
    }
    loading = false;
  }

  onMount(() => {
    fetchTickets();
  });

  // Determine the border color based on ticket status.
  function getBorderColor(status: string) {
    if (status === 'Pending') return '#fbbf24'; // yellow
    if (status === 'Completed') return '#10b981'; // green
    return 'transparent';
  }

  // Update a ticket's status to Completed and set date_resolved in the database.
  async function markAsResolved(ticketId: string) {
    const resolvedDate = new Date().toISOString();
    const { data, error } = await supabase
      .from('Tickets')
      .update({ status: 'Completed', date_resolved: resolvedDate })
      .eq('id', ticketId)
      .select();

    if (error) {
      console.error('Error updating ticket to Completed:', error);
      alert('Failed to mark ticket as resolved. Check console for details.');
    } else {
      console.log('Ticket updated to Completed:', data);
      // Re-fetch tickets to ensure UI reflects changes
      await fetchTickets();
    }
  }

  // Update a ticket's status to Pending and clear date_resolved in the database.
  async function reopenTicket(ticketId: string) {
    const { data, error } = await supabase
      .from('Tickets')
      .update({ status: 'Pending', date_resolved: null })
      .eq('id', ticketId)
      .select();

    if (error) {
      console.error('Error updating ticket to Pending:', error);
      alert('Failed to re-open ticket. Check console for details.');
    } else {
      console.log('Ticket updated to Pending:', data);
      // Re-fetch tickets to ensure UI reflects changes
      await fetchTickets();
    }
  }
</script>

<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
  <h1 class="text-3xl font-bold text-gray-900 mb-8">Service Request Tickets (Venue Staff)</h1>

  {#if loading}
    <p>Loading tickets...</p>
  {:else if errorMsg}
    <p class="text-red-600 text-center">{errorMsg}</p>
  {:else if tickets.length === 0}
    <div class="text-center py-12 bg-gray-50 rounded-lg">
      <p class="text-gray-500">No tickets available.</p>
    </div>
  {:else}
    <div class="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
      {#each tickets as ticket}
        <div 
          class="bg-white rounded-lg shadow p-6 flex flex-col justify-between"
          style="border-top: 4px solid {getBorderColor(ticket.status)}"
        >
          <div>
            <div class="flex justify-between items-start mb-4">
              <h3 class="text-lg font-semibold text-gray-900">
                {ticket.event ? ticket.event.event_name : ticket.event_id}
              </h3>
            </div>
            <div class="space-y-2 text-sm text-gray-600">
              <p>
                <span class="font-medium">Ticket Owner:</span>
                {ticket.Profiles ? `${ticket.Profiles.first_name} ${ticket.Profiles.last_name}` : ticket.ticket_owner}
              </p>
              <p>
                <span class="font-medium">Service:</span> {ticket.service}
              </p>
              <p>
                <span class="font-medium">Priority:</span> {ticket.priority}
              </p>
              <p>
                <span class="font-medium">Status:</span> {ticket.status}
              </p>
              <p>
                <span class="font-medium">Submitted:</span> {new Date(ticket.date_created).toLocaleDateString()}
              </p>
              {#if ticket.date_resolved}
                <p>
                  <span class="font-medium">Resolved:</span> {new Date(ticket.date_resolved).toLocaleDateString()}
                </p>
              {/if}
              <p>
                <span class="font-medium">Description:</span> {ticket.description}
              </p>
            </div>
          </div>
          <div>
            {#if ticket.status !== 'Completed'}
              <button 
                on:click={() => markAsResolved(ticket.id)}
                class="mt-4 w-full px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 transition-colors"
              >
                Mark as Resolved
              </button>
            {:else}
              <button 
                on:click={() => reopenTicket(ticket.id)}
                class="mt-4 w-full px-4 py-2 bg-gray-300 text-gray-800 rounded-md hover:bg-gray-400 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-400 transition-colors"
              >
                Re-open Ticket
              </button>
            {/if}
          </div>
        </div>
      {/each}
    </div>
  {/if}
</div>

<style>
  /* Additional styling if needed */
</style>
