<script lang="ts">
  import { supabase } from '$lib/supabaseClient';
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  
  let showCreateForm = $state(false);
  let events: any = $state([]);
  // Variables for edit functionality
  let showEditForm = $state(false);
  let currentEvent: any = $state(null);
  
  // Form fields for event creation
  let eventName = '';
  let venueName = '';
  let venueAddress = '';
  let venuePhone = '';
  let salesContact = '';
  let salesEmail = '';
  let venueWebsite = '';
  let eventDate = '';

  async function fetchEvents() {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('User not authenticated');

      const { data, error } = await supabase
          .from('events')
          .select('*')
          .eq('user_id', user.id);

      if (error) throw error;
      events = data;
    } catch (error) {
      console.error('Error fetching events:', error);
    }
  }

  onMount(async () => {
    // Load events for event creation
    await fetchEvents();
    // Also load my submitted tickets
    await getCurrentUser();
    await fetchMyTickets();
  });
  
  async function handleCreateEvent(e: SubmitEvent) {
    e.preventDefault();
  
    try {
      // Get the current user
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('User not authenticated');

      // Insert into Supabase
      const { data, error } = await supabase
          .from('events')
          .insert([
              {
                  user_id: user.id,
                  event_name: eventName,
                  venue_name: venueName,
                  venue_address: venueAddress,
                  venue_phone: venuePhone,
                  sales_contact: salesContact,
                  sales_email: salesEmail,
                  venue_website: venueWebsite,
                  event_date: eventDate
              }
          ])
          .select();

      if (error) throw error;
      // Add new event to local state
      events = [...events, data[0]];
      resetForm();
    } catch (error) {
      console.error('Error creating event:', error);
    }
  }
  
  function resetForm() {
    eventName = '';
    venueName = '';
    venueAddress = '';
    venuePhone = '';
    salesContact = '';
    salesEmail = '';
    venueWebsite = '';
    eventDate = '';
    showCreateForm = false;
  }

  async function handleRemoveEvent(eventId: string) {
    const confirmed = window.confirm('Are you sure you want to remove this event?');
    if (!confirmed) return;
    try {
      // Delete from Supabase
      const { error } = await supabase
          .from('events')
          .delete()
          .eq('id', eventId);
      if (error) throw error;
      // Remove from local state (this updates the UI)
      events = events.filter((event: any) => event.id !== eventId);
    } catch (error) {
      console.error('Error removing event:', error);
    }
  }

  // Function to open edit modal
  function openEditModal(event: any) {
    currentEvent = { ...event };  // Clone the event to avoid direct mutation
    showEditForm = true;
  }

  // Function to close edit modal
  function closeEditModal() {
    currentEvent = null;
    showEditForm = false;
  }

  // Function to handle event updates
  async function handleEditEvent(e: SubmitEvent) {
    e.preventDefault();
    try {
      const { error } = await supabase
          .from('events')
          .update({
              event_name: currentEvent.event_name,
              venue_name: currentEvent.venue_name,
              venue_address: currentEvent.venue_address,
              venue_phone: currentEvent.venue_phone,
              sales_contact: currentEvent.sales_contact,
              sales_email: currentEvent.sales_email,
              venue_website: currentEvent.venue_website,
              event_date: currentEvent.event_date
          })
          .eq('id', currentEvent.id);
      if (error) throw error;
      // Update the event in local state
      events = events.map((event: any) => 
          event.id === currentEvent.id ? currentEvent : event
      );
      closeEditModal();
    } catch (error) {
      console.error('Error updating event:', error);
    }
  }

  // Ticket interface for submitted tickets.
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

  let currentUserId = '';
  let myTickets = $state([]); // use reactive state
  let ticketsLoading = $state(true);
  let ticketsError = $state('');

  async function getCurrentUser() {
    const { data: { user }, error } = await supabase.auth.getUser();
    if (error || !user) {
      console.error('Error getting user:', error);
    } else {
      currentUserId = user.id;
    }
  }

  async function fetchMyTickets() {
    if (!currentUserId) return;
    const { data, error } = await supabase
      .from('Tickets')
      .select('*, event:Events(title), Profiles(first_name, last_name)')
      .eq('ticket_owner', currentUserId);

    if (error) {
      console.error('Error fetching my tickets:', error);
      ticketsError = 'Error fetching your tickets.';
    } else {
      myTickets = data as Ticket[];
    }
    ticketsLoading = false;
  }

  // Helper function for card border color based on status.
  function getBorderColor(status: string) {
    if (status === 'Pending') return '#d1d5db'; // light grey
    if (status === 'In Progress') return '#fbbf24'; // yellow
    if (status === 'Completed') return '#10b981'; // green
    return 'transparent';
  }
</script>

<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
  <!-- Submit a Request Button -->
  <div class="flex justify-center items-center space-x-4 mt-8 mb-4">
    <h1 class="text-3xl font-bold text-gray-900">Service Request Tickets</h1>
    <a 
      href="/dashboard/event_manager/tickets/submit" 
      class="bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 transition-colors"
    >
      Submit a Request
    </a>
  </div>
  

  <!-- My Submitted Tickets Section -->
  <h2 class="text-2xl font-bold text-gray-900 mb-4">My Submitted Tickets</h2>
  
  {#if ticketsLoading}
    <p>Loading your tickets...</p>
  {:else if ticketsError}
    <p class="text-red-600 text-center">{ticketsError}</p>
  {:else if myTickets.length === 0}
    <div class="text-center py-12 bg-gray-50 rounded-lg">
      <p class="text-gray-500">You haven't submitted any tickets yet.</p>
    </div>
  {:else}
    <div class="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
      {#each myTickets as ticket}
        <div 
          class="bg-white rounded-lg shadow p-6"
          style="border-top: 4px solid {getBorderColor(ticket.status)}"
        >
          <!-- Header: Event Title and Ticket Status -->
          <div class="flex justify-between items-center mb-4">
            <h3 class="text-lg font-semibold text-gray-900">
              {ticket.event ? ticket.event.title : ticket.event_id}
            </h3>
            <div class="text-xs text-gray-500 text-right">{ticket.status}</div>
          </div>
          <!-- Ticket Details -->
          <div class="space-y-2 text-sm text-gray-600">
            <p>
              <span class="font-medium">Ticket Owner:</span>
              {ticket.Profiles ? `${ticket.Profiles.first_name} ${ticket.Profiles.last_name}` : ticket.ticket_owner}
            </p>
            <p><span class="font-medium">Service:</span> {ticket.service}</p>
            <p><span class="font-medium">Description:</span> {ticket.description}</p>
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
        </div>
      {/each}
    </div>
  {/if}
</div>
