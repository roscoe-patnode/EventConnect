<script lang="ts">
  import { supabase } from '$lib/supabaseClient';
  import { onMount } from 'svelte';


    class Venue {
        id = "";
        name = "";
        address = "";
        phone = "";
        website = "";
        totalSpace = 0;
        services:string[] = [];

        constructor(id:string, name:string, address:string, phone:string, website:string, totalSpace:number, services:string[]) {
            this.id = id;
            this.name = name;
            this.address = address;
            this.phone = phone;
            this.website = website;
            this.totalSpace = totalSpace;
            this.services = services;
        }
    }
    let venue:Venue = $state(new Venue("", "", "", "", "", 0, []));
    let showSelectVenue = $state(false);
    let selectVenueId = $state('');
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

  let tickets: Ticket[] = $state([]);
  let loading = $state(true);
  let errorMsg = '';

    async function fetchVenue() {
        let hasVenue = false;
        try {
            const {data, error} = await supabase
                .from('VenueStaff')
                .select('*');
            if (error) throw error;
            console.log(data);
            if(data.length > 0) {
                hasVenue = true;
                const { data: venueData, error: venueError } = await supabase
                    .from('Venues')
                    .select('*')
                    .eq('id', data[0].venue_id);
                if (venueError) throw venueError;
                venue = new Venue(venueData![0].id, venueData![0].name, venueData![0].address, venueData![0].phone, venueData![0].website, venueData![0].total_space, venueData![0].services);
            }
        } catch (error) {
            console.error("Error fetching Venues", error);
        }
        if(!hasVenue) {
            showSelectVenue = true;
        }
    }
    async function handleSelectVenue() {
        try {
            const { data: venueData, error: venueError } = await supabase
                .from('Venues')
                .select('*')
                .eq('id', selectVenueId);
            if (venueError) throw venueError;
            if (venueData.length === 0)
                return;
            else {
                venue = new Venue(venueData![0].id, venueData![0].name, venueData![0].address, venueData![0].phone, venueData![0].website, venueData![0].total_space, venueData![0].services);
                const { data: userData } = await supabase.auth.getUser();
                try {
                    const { error } = await supabase
                        .from("VenueStaff")
                        .insert([
                            {
                                id: userData.user!.id,
                                venue_id: selectVenueId
                            }
                        ])
                        selectVenueId = "";
                        if (error) throw error;
                        await fetchTickets();
                        tickets = [...tickets];
                        console.log("Updating tickets");
                        showSelectVenue = false;
                        
                } catch (error) {
                    console.error ("Error assigning Venue:", error);
                }
            }
        } catch (error) {
            console.error("Error select Venue from given ID:", error);
        }
    }


  // Fetch tickets, joining the Events table (pulling "title") and the Profiles table.
  async function fetchTickets() {
    const { data: userData } = await supabase.auth.getUser();
    const { data, error } = await supabase
      .from('venue_staff_access_tickets')
      .select('*')
      .eq('staff_id', userData.user!.id);
    console.log(data);

    console.log('Fetched tickets:', data, 'Error:', error);

    if (error) {
      console.error('Error fetching tickets:', error);
      errorMsg = 'Error fetching tickets. Please try again later.';
    } else {
      let formattedData = data.map( row => ({
        ...row,
        event: {title: row.title},
        Profiles: {
            first_name: row.first_name,
            last_name: row.last_name
        }
      }))
      tickets = formattedData as Ticket[];
    }
    loading = false;
  }

  onMount(() => {
    fetchVenue();
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

{#if showSelectVenue}
<div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4">
    <div class="bg-white rounded-lg shadow-xl max-w-2xl w-full p-6">
        <div class="flex justify-between items-center mb-6">
            <h2 class="text-2xl font-semibold text-gray-900">Enter Venue ID</h2>
        </div>
        
        <form onsubmit={handleSelectVenue} class="space-y-6">

            <div>
                <label for="selectVenueId" class="block text-sm font-medium text-gray-700">Enter the Venue ID given to you by the Venue Admin</label>
                <input
                    type ="text"
                    id="removeServiceName"
                    bind:value={selectVenueId}
                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                    required
                />
            </div>
                    <div class="flex justify-end space-x-4">
                        <button
                            type="submit"
                            class="px-4 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                        >
                            Submit
                        </button>
                    </div>
                </form>
            </div>
        </div>
{/if}
<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <div class="flex justify-between items-center mb-8">
        <h1 class="text-3xl font-bold text-gray-900">Venue</h1>
    </div>
    <div class="bg-white shadow-lg rounded-lg p-6 max-w-md w-full">
        <h3 class="text-xl font-bold text-gray-900 mb-4">{venue.name}</h3>
        <div class="space-y-2 text-gray-700">
            <p><span class="font-semibold">Address:</span> {venue.address}</p>
            <p><span class="font-semibold">Phone:</span> {venue.phone}</p>
            <p><span class="font-semibold">Website:</span> <a target="_blank" href="{venue.website}" class="text-blue-600 hover:underline">{venue.website}</a></p>
            <p><span class="font-semibold">Total Space (ft²):</span> {venue.totalSpace}</p>
            <div class="flex-col items-center">
            <h1 class="text-xl font-semibold text-gray-800">Services</h1>
            <div class="flex flex-wrap gap-2 text-gray-700 mt-2">
                {#each venue.services as service}
                    <p><span class="font-semibold bg-gray-200 text-gray-900 px-3 py-1 rounded-lg text-sm">{service}</span></p>
                {/each}
            </div>
        </div>
        </div>
    </div>
</div>



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
                onclick={() => takeTask(ticket.id)}
                class="mt-4 w-full px-4 py-2 bg-gray-300 text-gray-800 rounded-md hover:bg-gray-400 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-400 transition-colors"
              >
                Take Task
              </button>
            {:else if ticket.status === 'In Progress'}
              <button 
                onclick={() => markAsCompleted(ticket.id)}
                class="mt-4 w-full px-4 py-2 bg-gray-300 text-gray-800 rounded-md hover:bg-gray-400 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-400 transition-colors"
              >
                Mark as Completed
              </button>
            {:else if ticket.status === 'Completed'}
              <button 
                onclick={() => reopenTicket(ticket.id)}
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
