<script lang="ts">

    import { supabase } from "$lib/supabaseClient";
    import { onMount } from 'svelte';

    // Create and event vars
    let showCreateEventForm = $state(false);

    // Variables for edit functionality
    let showEditForm = $state(false);
    let currentEvent:any = $state(null);

    
    // Event Form fields
    let eventTitle = $state('');
    let eventExpectAttend = $state(0);
    let eventStartDate = $state('');
    let eventEndDate = $state('');
    let eventVenueId = $state('');
    let eventEventSpace = $state('');
    let eventSpaceSetup = $state('');


    // Collab invite vars
    let showInviteForm = $state(false);
    let currentInviteEvent:any = $state(null);
    let inviteEmail = '';
    let inviteLoading = $state(false);
    let inviteError = $state('');
    let inviteSuccess = $state('');

    // Class to store Venue information
    class Venue {
        id = "";
        name = "";
        address = "";
        phone = "";
        website = "";
        totalSpace = 0;
        services = [];

        constructor(id:string, name:string, address:string, phone:string, website:string, totalSpace:number, services:[]) {
            this.id = id;
            this.name = name;
            this.address = address;
            this.phone = phone;
            this.website = website;
            this.totalSpace = totalSpace;
            this.services = services;
        }
    }

    // Classes to store Event information
    class EventSpace {
        id = "";
        name = "";
        size = 0;
        ceilings = 0;
        spaceSetups = new Map();

        constructor(id:string, name:string, size:number, ceilings:number) {
            this.id = id;
            this.name = name;
            this.size = size;
            this.ceilings = ceilings;
        }
    }
    class Event {
        id = "";
        title = "";
        dates = [];
        expectAttend = 0;
        bookedSpaces:any = [];

        constructor(id:string, title:string, dates:[], expectAttend:number) {
            this.id = id;
            this.title = title;
            this.dates = dates;
            this.expectAttend = expectAttend;
        }
    }
    // Venues array
    let venues:any = $state([]);
    // Events array
    let events:any = $state([]);
    // All event spaces
    let allEventSpaces = new Map();

    async function fetchVenues() {
        try {
            const {data, error} = await supabase
                .from('Venues')
                .select('*');
            if (error) throw error;
            for (const row of data) {
                venues.push(new Venue(row.id, row.name, row.address, row.phone, row.website, row.total_space, row.services));
            }
        } catch (error) {
            console.error("Error fetching Venues", error);
        }
    }

    async function fetchVenueEventSpaces() {
        // Get Venue Event Spaces
        try {
            const { data, error } = await supabase
                .from('EventSpaces')
                .select('*');
            if (error) throw error;
            for (const row of data) {
                allEventSpaces.set(row.id, new EventSpace(row.id, row.name, row.size, row.ceilings));
            }
        } catch(error) {
            console.error("Error fetching Venue Event Spaces", error);
        }

        // Get Event Space Setups
        try {
            const { data, error } = await supabase
                .from('SpaceSetups')
                .select('*');
            if (error) throw error;
            for (const row of data) {
                allEventSpaces.get(row.event_space_id).spaceSetups.set(row.name, row.capacity);
            }
        } catch(error) {
            console.error("Error fetching Event Space Setups")
        }
    }

    async function fetchEvents() {
        try {
            const { data: { user } } = await supabase.auth.getUser();
            
            if (!user) throw new Error('User not authenticated');

            // Get Events and add event to array
            const { data, error } = await supabase
                .from('Events')
                .select('*');

            if (error) throw error;
            for (const row of data) {
                events.push(new Event(row.id, row.title, row.dates, row.expect_attend));
            }
        } catch (error) {
            console.error('Error fetching events:', error);
        }

        // Get Event Spaces
        try {
            const { data, error } = await supabase
                .from('BookedEventSpacesList')
                .select('*');
            if (error) throw error;
            for (const row of data) {
                if (error) throw error;
                for (const row of data) {
                    for (const e of events) {
                        if (e.id = row.event_id) {
                            e.bookedSpaces.push(allEventSpaces.get(row.event_space_id))
                            break;
                        }
                    }
                }
            }
            
        } catch (error) {
            console.error("Error fetching Event Spaces", error)
        }

    }

    onMount(async () => {// Loading the database info from supabase
        await fetchVenues();
        await fetchVenueEventSpaces();
        await fetchEvents();
    });
    
    async function handleCreateEvent(e: SubmitEvent) {
        e.preventDefault();
        try {
            // Get the current user
            const { data: { user } } = await supabase.auth.getUser();
            
            if (!user) throw new Error('User not authenticated');
            console.log(user)
            const arrDates = [];
            for(const dt=new Date(eventStartDate); dt<=new Date(eventEndDate); dt.setDate(dt.getDate()+1)){
                arrDates.push(new Date(dt));
            }

            // Insert into Events Table
            const { data, error } = await supabase
                .from('Events')
                .insert([
                    {
                        title: eventTitle,
                        dates: arrDates,
                        expect_attend: eventExpectAttend,
                        venue_id: eventVenueId
                    }
                ])
                .select('*');

            if (error) throw error;
            // Add new event to local state
            events = [...events, data[0]];
            resetEventForm();

        } catch (error) {
            console.error('Error creating event:', error);
        }
        
    }
    
    function resetEventForm() {
        eventTitle = '';
        eventExpectAttend = 0;
        eventStartDate = '';
        eventEndDate = '';
        showCreateEventForm = false;
    }

    async function handleRemoveEvent(eventId: string) {
        const confirmed = window.confirm('Are you sure you want to remove this event?');
    
        if (!confirmed) return;

        try {
            // Delete from Supabase
            const { error } = await supabase
                .from('Events')
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
        eventVenueId = "";
        showEditForm = false;
    }

    // Function to handle event updates
    async function handleEditEvent(e: SubmitEvent) {
        e.preventDefault();
        const arrDates = [];
        for(const dt=new Date(currentEvent.dates[0]); dt<=new Date(currentEvent.dates[currentEvent.dates.length-1]); dt.setDate(dt.getDate()+1)){
            arrDates.push(new Date(dt));
        }
        try {
            // Update events in database
            const { error } = await supabase
                .from('Events')
                .update({
                    title: currentEvent.title,
                    expect_attend: currentEvent.expectAttend,
                    dates: arrDates,
                    venue_id: eventVenueId
                })
                .eq('id', currentEvent.id);

            if (error) throw error;

            // Update the event in local state (on UI)
            events = events.map((event: any) => 
                event.id === currentEvent.id ? currentEvent : event
            );

            closeEditModal();

        } catch (error) {
            console.error('Error updating event:', error);
        }
    }

    // Function to open the invite modal
    function inviteCollaborator(event: any) {
        currentInviteEvent = { ...event };
        showInviteForm = true;
    }

    // Function to close the invite modal
    function closeInviteModal() {
        currentInviteEvent = null;
        inviteEmail = '';
        inviteError = '';
        inviteSuccess = '';
        showInviteForm = false;
    }

    // Function to handle the invitation process
    async function handleInviteCollaborator(e: SubmitEvent) {
        e.preventDefault();
        inviteLoading = true;
        inviteError = '';
        inviteSuccess = '';

        try {
            // Get the current user
            const { data: { user } } = await supabase.auth.getUser();
            
            if (!user) throw new Error('User not authenticated');
            
            // Check if the invited user exists in the system
            const { data: existingUsers, error: userQueryError } = await supabase
                .from('Profiles')
                .select('id, email, user_type')
                .eq('email', inviteEmail);
            
            if (userQueryError) throw userQueryError;
            
            let invitedUserId = null;
            let needsEmailInvite = false;
            
            if (existingUsers && existingUsers.length > 0) {
                // User exists in the system
                invitedUserId = existingUsers[0].id;
            } else {
                // User doesn't exist, we'll need to send an email
                needsEmailInvite = true;
            }

            // Create or find a chat room between these users
            const { data: existingChatRoom, error: chatRoomQueryError } = await supabase
                .from('chat_rooms')
                .select('id')
                .or(`(user1_id.eq.${user.id}.and.user2_id.eq.${invitedUserId || 'null'}),(user1_id.eq.${invitedUserId || 'null'}.and.user2_id.eq.${user.id})`)
                .maybeSingle();
                
            if (chatRoomQueryError) throw chatRoomQueryError;
            
            let chatRoomId;
            
            if (existingChatRoom) {
                // Chat room already exists
                chatRoomId = existingChatRoom.id;
            } else {
                // Create a new chat room
                const { data: newChatRoom, error: createChatRoomError } = await supabase
                    .from('chat_rooms')
                    .insert({
                        user1_id: user.id,
                        user2_id: invitedUserId, // This will be null if the user doesn't exist yet
                        created_at: new Date().toISOString(),
                        pending_invitee_email: needsEmailInvite ? inviteEmail : null
                    })
                    .select();
                    
                if (createChatRoomError) throw createChatRoomError;
                
                chatRoomId = newChatRoom[0].id;
            }
            
            // Send the collaboration invitation message
            const { error: sendMessageError } = await supabase
                .from('messages')
                .insert({
                    chat_room_id: chatRoomId,
                    sender_id: user.id,
                    message_type: 'collaboration_invite',
                    content: JSON.stringify({
                        event_id: currentInviteEvent.id,
                        event_name: currentInviteEvent.event_name,
                        event_date: currentInviteEvent.event_date,
                        venue_name: currentInviteEvent.venue_name
                    }),
                    created_at: new Date().toISOString(),
                    status: 'sent'
                });
                
            if (sendMessageError) throw sendMessageError;
            
            // If the user doesn't exist, send an email invitation
            if (needsEmailInvite) {
                // This would typically be handled by a server function or edge function in production
                // For now, we'll just log it and update our UI
                console.log(`Would send email to ${inviteEmail} about collaboration invitation`);
                
                // Supabase Edge Functions or a serverless function
                const { error: emailError } = await supabase.functions.invoke('send-collaboration-email', {
                    body: { 
                        email: inviteEmail, 
                        eventName: currentInviteEvent.event_name,
                        inviterName: user.email || "A facility owner",
                        signupLink: `https://yourdomain.com/signup?email=${encodeURIComponent(inviteEmail)}&invite=true` 
                    }
                });
                if (emailError) throw emailError;
            }
            
            inviteSuccess = `Invitation sent to ${inviteEmail}!`;
            setTimeout(() => closeInviteModal(), 2000);
            
        } catch (error) {
            console.error('Error sending invitation:', error);
            inviteError = 'Failed to send invitation. Please try again.';
        } finally {
            inviteLoading = false;
        }
    }

</script>

<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <div class="flex justify-between items-center mb-8">
        <h1 class="text-3xl font-bold text-gray-900">Events</h1>
            <!-- Create Event Button -->
            <button 
                onclick={() => showCreateEventForm = true}
                class="bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 transition-colors"
            >
                Create New Event
            </button>
    </div>
    
    <!-- Create Form modal -->
    {#if showCreateEventForm}
        <div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4">
            <div class="bg-white rounded-lg shadow-xl max-w-2xl w-full p-6">
                <div class="flex justify-between items-center mb-6">
                    <h2 class="text-2xl font-semibold text-gray-900">Create New Event</h2>
                    <!-- svelte-ignore a11y_consider_explicit_label -->
                    <button 
                        onclick={resetEventForm}
                        class="text-gray-400 hover:text-gray-500"
                    >
                        <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                    </button>
                </div>
                
                <form onsubmit={handleCreateEvent} class="space-y-6">
                    <div>
                        <label for="eventTitle" class="block text-sm font-medium text-gray-700">Event Title</label>
                        <input
                            type="text"
                            id="eventTitle"
                            bind:value={eventTitle}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        />
                    </div>

                    <div>
                        <label for="eventExpectAttend" class="block text-sm font-medium text-gray-700">Expected Attendance</label>
                        <input
                            type="number"
                            id="eventExpectAttend"
                            bind:value={eventExpectAttend}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        />
                    </div>

                    <div>
                        <label for="eventStartDate" class="block text-sm font-medium text-gray-700">Event Start Date</label>
                        <input
                            type="date"
                            id="eventStartDate"
                            bind:value={eventStartDate}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        />
                    </div>

                    <div>
                        <label for="eventEndDate" class="block text-sm font-medium text-gray-700">Event End Date</label>
                        <input
                            type="date"
                            id="eventEndDate"
                            bind:value={eventEndDate}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        />
                    </div>

                    <div>
                        <label for="eventVenueId" class="block text-sm font-medium text-gray-700">Venue</label>
                        <select
                            id="eventVenueId"
                            bind:value={eventVenueId}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        >
                        {#each venues as venue}
                        <option value={venue.id}>{venue.name}</option>
                        {/each}
                        </select>
                    </div>
                    
                    <div class="flex justify-end space-x-4">
                        <button
                            type="button"
                            onclick={resetEventForm}
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
    <!-- && currentEvent in if may be redundant will double check maybe? -->
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
                        <label for="editEventTitle" class="block text-sm font-medium text-gray-700">Event Title</label>
                        <input
                            type="text"
                            id="editEventTitle"
                            bind:value={currentEvent.title}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        />
                    </div>

                    <div>
                        <label for="editEventExpectAttend" class="block text-sm font-medium text-gray-700">Expected Attendance</label>
                        <input
                            type="number"
                            id="editEventExpectAttend"
                            bind:value={currentEvent.expectAttend}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        />
                    </div>

                    <div>
                        <label for="editEventStartDate" class="block text-sm font-medium text-gray-700">Event Start Date</label>
                        <input
                            type="date"
                            id="editEventStartDate"
                            bind:value={currentEvent.dates[0]}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        />
                    </div>

                    <div>
                        <label for="editEventEndDate" class="block text-sm font-medium text-gray-700">Event End Date</label>
                        <input
                            type="date"
                            id="editEventEndDate"
                            bind:value={currentEvent.dates[currentEvent.dates.length - 1]}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        />
                    </div>

                    <div>
                        <label for="editEventVenueId" class="block text-sm font-medium text-gray-700">Venue</label>
                        <select
                            id="editEventVenueId"
                            bind:value={eventVenueId}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        >
                        {#each venues as venue}
                        <option value={venue.id}>{venue.name}</option>
                        {/each}
                        </select>
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
                            <h3 class="text-xl font-bold text-gray-900">{event.title}</h3>
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

                                    <!-- svelte-ignore a11y_consider_explicit_label -->
                                    <!-- Invite to collab -->
                                    <button 
                                        onclick={() => inviteCollaborator(event)}
                                        class="text-gray-400 hover:text-green-600 transition-colors"
                                        title="Invite collaborator"
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
                                                d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" 
                                            />
                                        </svg>
                                    </button>
                                </div>
                        </div>
                        <!-- Event Cards -->
                        <div class="space-y-2 text-sm text-gray-600">
                            <p><span class="font-medium">Expected Attendance:</span> {event.expectAttend}</p>
                            <p><span class="font-medium">Start Date:</span> {event.dates[0]}</p>
                            <p><span class="font-medium">End Date:</span> {event.dates[event.dates.length - 1]}</p>
                        </div>
                    </div>
                {/each}
            </div>
        {/if}
    </div>
</div>