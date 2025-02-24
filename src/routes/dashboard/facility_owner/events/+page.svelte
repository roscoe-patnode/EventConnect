<script lang="ts">
    import { supabase } from "$lib/supabaseClient";
    import { onMount } from 'svelte';

    let showCreateForm = $state(false);
    let events:any = $state([]);
    // Variables for edit functionality
    let showEditForm = $state(false);
    let currentEvent:any = $state(null);
    
    // Form fields
    let eventName = '';
    let venueName = '';
    let venueAddress = '';
    let venuePhone = '';
    let salesContact = '';
    let salesEmail = '';
    let venueWebsite = '';

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

    onMount(async () => {// Loading the database info from supabase
        await fetchEvents();
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
                        venue_website: venueWebsite
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
            events = events.filter((event:any) => event.id !== eventId);

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
                    venue_website: currentEvent.venue_website
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

</script>

<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <div class="flex justify-between items-center mb-8">
        <h1 class="text-3xl font-bold text-gray-900">Events</h1>
            <!-- Create Event Button -->
            <button 
                onclick={() => showCreateForm = true}
                class="bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 transition-colors"
            >
                Create New Event
            </button>
    </div>
    
    <!-- Create Form modal -->
    {#if showCreateForm}
        <div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4">
            <div class="bg-white rounded-lg shadow-xl max-w-2xl w-full p-6">
                <div class="flex justify-between items-center mb-6">
                    <h2 class="text-2xl font-semibold text-gray-900">Create New Event</h2>
                    <!-- svelte-ignore a11y_consider_explicit_label -->
                    <button 
                        onclick={resetForm}
                        class="text-gray-400 hover:text-gray-500"
                    >
                        <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                    </button>
                </div>
                
                <form onsubmit={handleCreateEvent} class="space-y-6">
                    <div>
                        <label for="eventName" class="block text-sm font-medium text-gray-700">Event Name</label>
                        <input
                            type="text"
                            id="eventName"
                            bind:value={eventName}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        />
                    </div>
                    
                    <div>
                        <label for="venueName" class="block text-sm font-medium text-gray-700">Venue Name</label>
                        <input
                            type="text"
                            id="venueName"
                            bind:value={venueName}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        />
                    </div>
                    
                    <div>
                        <label for="venueAddress" class="block text-sm font-medium text-gray-700">Venue Address</label>
                        <input
                            type="text"
                            id="venueAddress"
                            bind:value={venueAddress}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        />
                    </div>
                    
                    <div>
                        <label for="venuePhone" class="block text-sm font-medium text-gray-700">Venue Phone</label>
                        <input
                            type="tel"
                            id="venuePhone"
                            bind:value={venuePhone}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        />
                    </div>
                    
                    <div>
                        <label for="salesContact" class="block text-sm font-medium text-gray-700">Lead Event Sales Contact</label>
                        <input
                            type="text"
                            id="salesContact"
                            bind:value={salesContact}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        />
                    </div>
                    
                    <div>
                        <label for="salesEmail" class="block text-sm font-medium text-gray-700">Lead Event Sales Email</label>
                        <input
                            type="email"
                            id="salesEmail"
                            bind:value={salesEmail}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        />
                    </div>
                    
                    <div>
                        <label for="venueWebsite" class="block text-sm font-medium text-gray-700">Venue Website</label>
                        <input
                            type="url"
                            id="venueWebsite"
                            bind:value={venueWebsite}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        />
                    </div>
                    
                    <div class="flex justify-end space-x-4">
                        <button
                            type="button"
                            onclick={resetForm}
                            class="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                        >
                            Cancel
                        </button>
                        <button
                            type="submit"
                            class="px-4 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                        >
                            Create Event
                        </button>
                    </div>
                </form>
            </div>
        </div>
    {/if}

    <!-- Edit Form Modal -->
    {#if showEditForm && currentEvent}
        <div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4">
            <div class="bg-white rounded-lg shadow-xl max-w-2xl w-full p-6">
                <div class="flex justify-between items-center mb-6">
                    <h2 class="text-2xl font-semibold text-gray-900">Edit Event</h2>
                    <!-- svelte-ignore a11y_consider_explicit_label -->
                    <button 
                        onclick={closeEditModal}
                        class="text-gray-400 hover:text-gray-500"
                    >
                        <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                    </button>
                </div>
                
                <form onsubmit={handleEditEvent} class="space-y-6">
                    <div>
                        <label for="editEventName" class="block text-sm font-medium text-gray-700">Event Name</label>
                        <input
                            type="text"
                            id="editEventName"
                            bind:value={currentEvent.event_name}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        />
                    </div>
                    
                    <div>
                        <label for="editVenueName" class="block text-sm font-medium text-gray-700">Venue Name</label>
                        <input
                            type="text"
                            id="editVenueName"
                            bind:value={currentEvent.venue_name}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        />
                    </div>
                    
                    <div>
                        <label for="editVenueAddress" class="block text-sm font-medium text-gray-700">Venue Address</label>
                        <input
                            type="text"
                            id="editVenueAddress"
                            bind:value={currentEvent.venue_address}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        />
                    </div>
                    
                    <div>
                        <label for="editVenuePhone" class="block text-sm font-medium text-gray-700">Venue Phone</label>
                        <input
                            type="tel"
                            id="editVenuePhone"
                            bind:value={currentEvent.venue_phone}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        />
                    </div>
                    
                    <div>
                        <label for="editSalesContact" class="block text-sm font-medium text-gray-700">Lead Event Sales Contact</label>
                        <input
                            type="text"
                            id="editSalesContact"
                            bind:value={currentEvent.sales_contact}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        />
                    </div>
                    
                    <div>
                        <label for="editSalesEmail" class="block text-sm font-medium text-gray-700">Lead Event Sales Email</label>
                        <input
                            type="email"
                            id="editSalesEmail"
                            bind:value={currentEvent.sales_email}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        />
                    </div>
                    
                    <div>
                        <label for="editVenueWebsite" class="block text-sm font-medium text-gray-700">Venue Website</label>
                        <input
                            type="url"
                            id="editVenueWebsite"
                            bind:value={currentEvent.venue_website}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        />
                    </div>
                    
                    <div class="flex justify-end space-x-4">
                        <button
                            type="button"
                            onclick={closeEditModal}
                            class="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                        >
                            Cancel
                        </button>
                        <button
                            type="submit"
                            class="px-4 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                        >
                            Save Changes
                        </button>
                    </div>
                </form>
            </div>
        </div>
    {/if}   
    
    <!-- Events List -->
    <div class="mt-8">
        {#if events.length === 0}
            <div class="text-center py-12 bg-gray-50 rounded-lg">
                <p class="text-gray-500">No events created yet. Click "Create New Event" to get started.</p>
            </div>
        {:else}
            <div class="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
                {#each events as event}
                    <div class="bg-white rounded-lg shadow p-6">
                        <div class="flex justify-between items-start mb-4">
                            <h3 class="text-lg font-semibold text-gray-900">{event.event_name}</h3>
                                <div class="flex space-x-2">
                                    <!-- svelte-ignore a11y_consider_explicit_label -->
                                    <!-- Edit button -->
                                    <button 
                                        onclick={() => openEditModal(event)}
                                        class="text-gray-400 hover:text-indigo-600 transition-colors"
                                        title="Edit event"
                                    >
                                        <svg 
                                        xmlns="http://www.w3.org/2000/svg" 
                                        class="h-5 w-5" 
                                        fill="none" 
                                        viewBox="0 0 24 24" 
                                        stroke="currentColor"
                                        >
                                            <path 
                                                stroke-linecap="round" 
                                                stroke-linejoin="round" 
                                                stroke-width="2" 
                                                d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" 
                                            />
                                        </svg>
                                    </button>
                                    <!-- svelte-ignore a11y_consider_explicit_label -->
                                    <!-- Delete button -->
                                    <button 
                                        onclick={() => handleRemoveEvent(event.id)}
                                        class="text-gray-400 hover:text-red-600 transition-colors"
                                        title="Remove event"
                                    >
                                        <svg 
                                            xmlns="http://www.w3.org/2000/svg" 
                                            class="h-5 w-5" 
                                            fill="none" 
                                            viewBox="0 0 24 24" 
                                            stroke="currentColor"
                                        >
                                            <path 
                                                stroke-linecap="round" 
                                                stroke-linejoin="round" 
                                                stroke-width="2" 
                                                d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" 
                                            />
                                        </svg>
                                    </button>
                                </div>
                        </div>
                        <div class="space-y-2 text-sm text-gray-600">
                            <p><span class="font-medium">Venue:</span> {event.venue_name}</p>
                            <p><span class="font-medium">Address:</span> {event.venue_address}</p>
                            <p><span class="font-medium">Contact:</span> {event.sales_ontact}</p>
                            <p><span class="font-medium">Email:</span> {event.sales_email}</p>
                            <p>
                                <a href={event.venue_website} target="_blank" rel="noopener noreferrer" 
                                class="text-indigo-600 hover:text-indigo-800">
                                    Visit Website
                                </a>
                            </p>
                        </div>
                    </div>
                {/each}
            </div>
        {/if}
    </div>
</div>