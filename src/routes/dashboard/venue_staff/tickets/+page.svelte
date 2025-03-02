<script lang="ts">
    import { supabase } from '$lib/supabaseClient';
    import { onMount } from 'svelte';
  
    // Define the interface for a ticket
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
    }
  
    // Explicitly annotate the tickets array with the Ticket interface
    let tickets: Ticket[] = [];
  
    async function fetchTickets() {
      // Fetch tickets with a Pending status
      const { data, error } = await supabase
        .from('Tickets')
        .select('*')
        .eq('status', 'Pending');
  
      if (error) {
        console.error('Error fetching tickets:', error);
      } else {
        // Cast the fetched data to Ticket[]
        tickets = data as Ticket[];
      }
    }
  
    onMount(fetchTickets);
  </script>
  
  <h1>Service Request Ticket Queue (Venue Staff)</h1>
  
  {#if tickets.length > 0}
    <ul>
      {#each tickets as ticket}
        <li>
          <strong>Service:</strong> {ticket.service} - <strong>Priority:</strong> {ticket.priority}
          <p>{ticket.description}</p>
          <small>Submitted on {ticket.date_created} by {ticket.ticket_owner}</small>
        </li>
      {/each}
    </ul>
  {:else}
    <p>No pending tickets available.</p>
  {/if}
  