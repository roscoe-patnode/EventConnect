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
      title: string;
    };
    Profiles?: {
      first_name: string;
      last_name: string;
    };
  }

  let tickets: Ticket[] = [];
  let loading = true;
  let errorMsg = '';

  // Fetch tickets, joining the Events table (pulling "title") and the Profiles table.
  async function fetchTickets() {
    const { data, error } = await supabase
      .from('Tickets')
      .select('*, event:Events (title), Profiles (first_name, last_name)');

    console.log('Fetched tickets:', data, 'Error:', error);

    if (error) {
      console.error('Error fetching tickets:', error);
      errorMsg = 'Error fetching tickets. Please try again later.';
    } else {
      tickets = data as Ticket[];
    }
    loading = false;
  }

  onMount(() => {
    fetchTickets();
  });

  // Determine the top border color based on ticket status.
  function getBorderColor(status: string) {
    if (status === 'Pending') return '#d1d5db'; // light grey
    if (status === 'In Progress') return '#fbbf24'; // yellow
    if (status === 'Completed') return '#10b981'; // green
    return 'transparent';
  }

  // Update a ticket's status to In Progress (from Pending) and clear date_resolved.
  async function takeTask(ticketId: string) {
    const { data, error } = await supabase
      .from('Tickets')
      .update({ status: 'In Progress', date_resolved: null })
      .eq('id', ticketId)
      .select();

    if (error) {
      console.error('Error updating ticket:', error);
      alert('Failed to take task.');
    } else {
      console.log('Updated ticket:', data);
      await fetchTickets();
    }
  }

  // Update a ticket's status to Completed and set date_resolved.
  async function markAsCompleted(ticketId: string) {
    const resolvedDate = new Date().toISOString();
    const { data, error } = await supabase
      .from('Tickets')
      .update({ status: 'Completed', date_resolved: resolvedDate })
      .eq('id', ticketId)
      .select();

    if (error) {
      console.error('Error updating ticket:', error);
      alert('Failed to mark ticket as completed.');
    } else {
      console.log('Updated ticket:', data);
      await fetchTickets();
    }
  }

  // Update a ticket's status from Completed to In Progress (re-open ticket) and clear date_resolved.
  async function reopenTicket(ticketId: string) {
    const { data, error } = await supabase
      .from('Tickets')
      .update({ status: 'In Progress', date_resolved: null })
      .eq('id', ticketId)
      .select();

    if (error) {
      console.error('Error updating ticket:', error);
      alert('Failed to re-open ticket.');
    } else {
      console.log('Updated ticket:', data);
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
          <!-- Card Header: Event Title and Status -->
          <div class="flex justify-between items-center mb-4">
            <h3 class="text-lg font-semibold text-gray-900">
              {ticket.event ? ticket.event.title : ticket.event_id}
            </h3>
            <div class="text-xs text-gray-500 text-right">
              {ticket.status}
            </div>
          </div>
          <!-- Card Content -->
          <div class="space-y-2 text-sm text-gray-600">
            <p>
              <span class="font-medium">Ticket Owner:</span>
              {ticket.Profiles ? `${ticket.Profiles.first_name} ${ticket.Profiles.last_name}` : ticket.ticket_owner}
            </p>
            <p>
              <span class="font-medium">Service:</span> {ticket.service}
            </p>
            <p>
              <span class="font-medium">Description:</span> {ticket.description}
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
              <span class="font-medium">Priority:</span> {ticket.priority}
            </p>
          </div>
          <!-- Card Action Button -->
          <div>
            {#if ticket.status === 'Pending'}
              <button 
                on:click={() => takeTask(ticket.id)}
                class="mt-4 w-full px-4 py-2 bg-gray-300 text-gray-800 rounded-md hover:bg-gray-400 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-400 transition-colors"
              >
                Take Task
              </button>
            {:else if ticket.status === 'In Progress'}
              <button 
                on:click={() => markAsCompleted(ticket.id)}
                class="mt-4 w-full px-4 py-2 bg-gray-300 text-gray-800 rounded-md hover:bg-gray-400 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-400 transition-colors"
              >
                Mark as Completed
              </button>
            {:else if ticket.status === 'Completed'}
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
