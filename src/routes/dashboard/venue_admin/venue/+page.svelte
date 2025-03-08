<script lang="ts">

    import { supabase } from "$lib/supabaseClient";
    import { onMount } from 'svelte';

    // Variables used to check User Role
    let loading = $state(true);
    let userRole = $state("");

    // Edit Venue information form
    let showEditVenueForm = $state(false);
    let showVenueId = $state(false);

    // Service form
    let showAddServiceForm = $state(false);
    let showRemoveServiceForm = $state(false);
    let serviceName = $state("");
    let newServiceName = $state("");

    // Create EventSpace and SpaceSetup form variables
    let showCreateEventSpaceForm = $state(false);
    let showEditEventSpaceForm = $state(false);
    let showAddSetupForm = $state(false);
    let showRemoveSetupForm = $state(false);
    
    // Event Space form variables
    let eventSpaceName = $state("");
    let eventSpaceSize = $state(0);
    let eventSpaceCeilings = $state(0);
    let currentEventSpace:any = $state(null);

    // Space Setups for variables
    let setupName = $state("");
    let setupCapacity = $state(0);



    // Class to store Venue information
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

    // Classes to store Event information
    class EventSpace {
        id = "";
        name = "";
        size = 0;
        ceilings = 0;
        spaceSetups = new Map();

        constructor(id:string, name:string, size:number, ceilings:number, spaceSetups?:any) {
            this.id = id;
            this.name = name;
            this.size = size;
            this.ceilings = ceilings;
            if (spaceSetups) {
                this.spaceSetups = spaceSetups;
            }
        }
    }
    // Venue
    let venue:Venue = $state(new Venue("", "", "", "", "", 0, []));
    let editVenue:Venue = $state(new Venue("", "", "", "", "", 0, []));
    // All event spaces
    let eventSpaces = $state(new Map());

    let suggestedService = [ "Food & Beverage", "Audio/Visual", "Support Staff", "Furniture Rentals", "Off-Site Vendors", "Event Planning Services" ];

    async function fetchVenue() {
        let hasVenue = false;
        try {
            const { data: userData } = await supabase.auth.getUser();
            const {data, error} = await supabase
                .from('Venues')
                .select('*')
                .eq('venue_admin_id', userData.user!.id);
            if (error) throw error;
            if(data.length > 0) {
                hasVenue = true;
                venue = new Venue(data[0].id, data[0].name, data[0].address, data[0].phone, data[0].website, data[0].total_space, data[0].services);
            }
            console.log(hasVenue);
        } catch (error) {
            console.error("Error fetching Venues", error);
        }
        if(!hasVenue) {
            try {
                const { data: { user } } = await supabase.auth.getUser();
                if (!user) throw new Error('User not authenticated');

                console.log(user.id);

                const { data, error } = await supabase
                    .from('Venues')
                    .insert([{
                        venue_admin_id: user.id
                    }])
                    .select();
                if (error) throw error;
                venue = new Venue(data[0].id, data[0].name, data[0].address, data[0].phone, data[0].website, data[0].total_space, data[0].services);
            } catch (error) {
                console.error("Error creating blank Venue:", error);
            }

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
                eventSpaces = new Map(eventSpaces.set(row.id, new EventSpace(row.id, row.name, row.size, row.ceilings)));
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
                eventSpaces = new Map(eventSpaces); // Clone eventSpaces
                const eventSpace = eventSpaces.get(row.event_space_id);

                if (eventSpace) {
                    eventSpace.spaceSetups = new Map(eventSpace.spaceSetups); // Clone spaceSetups
                    eventSpace.spaceSetups.set(row.name, row.capacity);
                }
            }
        } catch(error) {
            console.error("Error fetching Event Space Setups")
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
    onMount(async () => {// Loading the database info from supabase
        await fetchVenue();
        await fetchVenueEventSpaces();
        await fetchRole();
        loading = false;
    });
    

    async function handleEditVenue() {
        if (editVenue.website.substring(0,7) != "http://" && editVenue.website.substring(0,8) != "https://") {
            editVenue.website = "https://" + editVenue.website;
        }
        try {
            const { error } = await supabase
                .from('Venues')
                .update([
                    {
                        name: editVenue.name,
                        address: editVenue.address,
                        phone: editVenue.phone,
                        website: editVenue.website,
                        total_space: editVenue.totalSpace
                    }
                ])
            .eq('id', venue.id);
            if (error) throw error
        } catch (error) {
            console.error("Error updating Venue:", error);
        }
        venue = editVenue;
        closeVenueForm();
    }

    async function handleAddService() {
        if (serviceName != "other") {
            newServiceName = serviceName;
        }
        if (venue.services.includes(newServiceName)) {
            alert("Cannot add service \"" + newServiceName + "\" because it already exists!")
            return;
        }
        venue.services = [... venue.services, newServiceName];
        try {
            const { error } = await supabase
                .from('Venues')
                .update([
                    {
                        services: venue.services
                    }
                ])
            .eq('id', venue.id);
            if (error) throw error
        } catch (error) {
            venue.services = venue.services.filter((service:string) => service !== newServiceName);
            console.error("Error adding service:", error);
        }
        venue = { ...venue};
        closeAddServiceForm();
    }
    async function handleRemoveService(removeServiceName:string) {
        venue.services = venue.services.filter((service:string) => service !== removeServiceName);
        try {
            const { data, error } = await supabase
                .from('Venues')
                .update([
                    {
                        services: venue.services
                    }
                ])
                .eq('id', venue.id);
            if (error) throw error
        } catch (error) {
            venue.services = [... venue.services, removeServiceName]
            console.error("Error removing service:", error);
        }
        venue = { ...venue};
        closeRemoveServiceForm();
    }

    async function handleCreateEventSpace() {
        try {
            const { data, error } = await supabase
                .from('EventSpaces')
                .insert([
                    {
                        name: eventSpaceName,
                        size: eventSpaceSize,
                        ceilings: eventSpaceCeilings,
                        venue_id: venue.id
                    }
                ])
                .select();
            if (error) throw error;
            eventSpaces = new Map(eventSpaces.set(data[0].id, new EventSpace(data[0].id, data[0].name, data[0].size, data[0].ceilings)));
        } catch(error) {
            console.error("Error creating Event Space: ", error);
        }
        closeCreateEventSpaceForm();
    }
    async function handleRemoveEventSpace(eventSpaceId:string) {
        try {
            const { error } = await supabase
                .from('EventSpaces')
                .delete()
                .eq('id', eventSpaceId);
            if (error) throw error;
            eventSpaces.delete(eventSpaceId);
            eventSpaces = new Map(eventSpaces);
        } catch(error) {
            console.error("Error removing Event Space:", error);
        }
    }
    async function handleEditEventSpace() {
        try {
            const { error } = await supabase
                .from('EventSpaces')
                .update([
                    {
                        name: currentEventSpace.name,
                        size: currentEventSpace.size,
                        ceilings: currentEventSpace.ceilings,
                    }
                ])
                .eq("id", currentEventSpace.id);
            if (error) throw error;

            eventSpaces = new Map(eventSpaces.set(currentEventSpace.id, currentEventSpace));
        } catch(error) {
            console.error("Error editing Event Space:", error);
        }
        
        closeEditEventSpaceForm();
    }

    async function handleAddSetup() {
        try {
            const { error } = await supabase
                .from('SpaceSetups')
                .insert([
                    {
                        event_space_id: currentEventSpace.id,
                        name: setupName,
                        capacity: setupCapacity
                    }
                ])
            eventSpaces = new Map(eventSpaces); // Clone eventSpaces
            const eventSpace = currentEventSpace;

            if (eventSpace) {
                eventSpace.spaceSetups = new Map(eventSpace.spaceSetups); // Clone spaceSetups
                currentEventSpace.spaceSetups.set(setupName, setupCapacity);
            }

        } catch(error) {
            console.error("Error adding Event Space Setup:", error);
        }
        
        closeAddSetupForm();
    }
    async function handleRemoveSetup() {
        try {
            console.log(currentEventSpace.id + setupName);
            const { data, error } = await supabase
                .from('SpaceSetups')
                .delete()
                .eq("event_space_id", currentEventSpace.id).eq("name", setupName);
            if (error) throw error;
            console.log(data);
            
            eventSpaces = new Map(eventSpaces); // Clone eventSpaces
            const eventSpace = currentEventSpace;

            if (eventSpace) {
                eventSpace.spaceSetups = new Map(eventSpace.spaceSetups); // Clone spaceSetups
                currentEventSpace.spaceSetups.delete(setupName);
            }
        } catch(error) {
            console.error("Error removing Event Space Setup:", error);
        }

        closeRemoveSetupForm();
    }


    async function openEditVenueForm(venue: any) {
        editVenue = { ... venue };
        showEditVenueForm = true;
    }
    async function closeVenueForm() {
        editVenue = new Venue("", "", "", "", "", 0, []);
        showEditVenueForm = false;
    }

    async function closeAddServiceForm() {
        serviceName = "";
        newServiceName = "";
        showAddServiceForm = false;
    }
    async function closeRemoveServiceForm() {
        showRemoveServiceForm = false;
    }

    async function closeCreateEventSpaceForm() {
        eventSpaceName = "";
        eventSpaceSize = 0;
        eventSpaceCeilings = 0;

        showCreateEventSpaceForm = false;
    }
    async function openEditEventSpaceForm(eventSpace:EventSpace) {
        currentEventSpace = { ...eventSpace};
        showEditEventSpaceForm = true;
        
    }
    async function closeEditEventSpaceForm() {
        eventSpaceName = "";
        eventSpaceSize = 0;
        eventSpaceCeilings = 0;
        currentEventSpace = null;

        showEditEventSpaceForm = false;
    }

    async function openAddSetupForm(eventSpace:EventSpace) {
        showAddSetupForm = true;
        currentEventSpace = eventSpace;
    }
    async function closeAddSetupForm() {
        currentEventSpace = null;
        showAddSetupForm = false;

        setupName = "";
        setupCapacity = 0;
    }
    async function openRemoveSetupForm(eventSpace:EventSpace) {
        showRemoveSetupForm = true;
        currentEventSpace = eventSpace;
    }
    async function closeRemoveSetupForm() {
        currentEventSpace = null;
        showRemoveSetupForm = false;

        setupName = "";
        setupCapacity = 0;
    }
</script>
<!-- Check if User has the Permissions to View Page -->
{#if userRole !== 'venue_admin' && !loading}
<div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4">
    <div class="fixed inset-0 bg-gray-900 bg-opacity-80 flex items-center justify-center p-6">
        <div class="bg-white rounded-2xl shadow-xl p-6 max-w-md text-center">
            <h2 class="text-2xl font-semibold text-gray-800">Access Denied</h2>
            <p class="text-gray-600 mt-2">You do not have permission to view this page.</p>
        </div>
    </div>
</div>
{:else}
<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <div class="flex justify-between items-center mb-8">
        <h1 class="text-3xl font-bold text-gray-900">Venue</h1>
            <!-- Create Event Button -->
            <button 
                onclick={() => openEditVenueForm(venue)}
                class="bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 transition-colors"
            >
                Edit Venue
            </button>
    </div>

    {#if showEditVenueForm}
        <div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4">
            <div class="bg-white rounded-lg shadow-xl max-w-2xl w-full p-6">
                <div class="flex justify-between items-center mb-6">
                    <h2 class="text-2xl font-semibold text-gray-900">Edit Venue Information</h2>
                    <!-- svelte-ignore a11y_consider_explicit_label -->
                    <button 
                        onclick={() => closeVenueForm()}
                        class="text-gray-400 hover:text-gray-500"
                    >
                        <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                    </button>
                </div>
                
                <form onsubmit={handleEditVenue} class="space-y-6">
                    <div>
                        <label for="venueName" class="block text-sm font-medium text-gray-700">Venue Name</label>
                        <input
                            type="text"
                            id="venueName"
                            bind:value={editVenue.name}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        />
                    </div>
                    <div>
                        <label for="venueAddress" class="block text-sm font-medium text-gray-700">Venue Address</label>
                        <input
                            type="text"
                            id="venueAddress"
                            bind:value={editVenue.address}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        />
                    </div>
                    <div>
                        <label for="venuePhone" class="block text-sm font-medium text-gray-700">Venue Phone Number</label>
                        <input
                            type="text"
                            id="venuePhone"
                            bind:value={editVenue.phone}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        />
                    </div>
                    <div>
                        <label for="venueWebsite" class="block text-sm font-medium text-gray-700">Venue Website</label>
                        <input
                            type="text"
                            id="venueWebsite"
                            bind:value={editVenue.website}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        />
                    </div>
                    <div>
                        <label for="venueTotalSpace" class="block text-sm font-medium text-gray-700">Total Space (ft²)</label>
                        <input
                            type="number"
                            id="venueTotalSpace"
                            bind:value={editVenue.totalSpace}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        />
                    </div>

                    <div class="flex justify-end space-x-4">
                        <button
                            type="button"
                            onclick={closeVenueForm}
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

    
    <div class="bg-white shadow-lg rounded-lg p-6 max-w-md w-full">
        <h3 class="text-xl font-bold text-gray-900 mb-4">{venue.name}</h3>
        <div class="space-y-2 text-gray-700">
          <p><span class="font-semibold">Venue ID (only share with trusted users):</span></p> {#if showVenueId} 
            <p>{venue.id}</p>
        {:else}
            
            <p><button 
                class="ml-2 text-blue-600 underline hover:text-blue-800 transition"
                onclick={() => showVenueId = true}
            >
                Click to reveal
            </button></p>
        {/if}
          <p><span class="font-semibold">Address:</span> {venue.address}</p>
          <p><span class="font-semibold">Phone:</span> {venue.phone}</p>
          <p><span class="font-semibold">Website:</span> <a target="_blank" href="{venue.website}" class="text-blue-600 hover:underline">{venue.website}</a></p>
          <p><span class="font-semibold">Total Space (ft²):</span> {venue.totalSpace}</p>
          <div class="flex-col items-center mb-8">
            <h1 class="text-xl font-semibold text-gray-800">Services
            <button onclick={() => showAddServiceForm = true}
                aria-label="Add Service"
                class="bg-indigo-600 text-white px-2 py-1 rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 transition-colors">
                <svg 
                    xmlns="http://www.w3.org/2000/svg" 
                    class="h-4 w-4" 
                    fill="none" 
                    viewBox="0 0 24 24" 
                    stroke="currentColor"
                >
                    <path 
                        stroke-linecap="round" 
                        stroke-linejoin="round" 
                        stroke-width="2" 
                        d="M12 4 V20 M4 12 H20" 
                    />
            </button>
            <button onclick={() => showRemoveServiceForm = true}
                aria-label="Remove Service"
                class="bg-red-600 text-white px-2 py-1 rounded-md hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 transition-colors">
                <svg 
                    xmlns="http://www.w3.org/2000/svg" 
                    class="h-4 w-4" 
                    fill="none" 
                    viewBox="0 0 24 24" 
                    stroke="currentColor"
                >
                    <path 
                        stroke-linecap="round" 
                        stroke-linejoin="round" 
                        stroke-width="2" 
                        d="M4 12 H20" 
                    />
                </svg>
            </button></h1>
            <div class="flex flex-wrap gap-2 text-gray-700 mb-2 mt-2">
                {#each venue.services as service}
                    <p><span class="font-semibold bg-gray-200 text-gray-900 px-3 py-1 rounded-lg text-sm">{service}</span></p>
                {/each}
            </div>
        </div>
        </div>
    </div>

    

    {#if showAddServiceForm}
        <div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4">
            <div class="bg-white rounded-lg shadow-xl max-w-2xl w-full p-6">
                <div class="flex justify-between items-center mb-6">
                    <h2 class="text-2xl font-semibold text-gray-900">Add a Service</h2>
                    <!-- svelte-ignore a11y_consider_explicit_label -->
                    <button 
                        onclick={closeAddServiceForm}
                        class="text-gray-400 hover:text-gray-500"
                    >
                        <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                    </button>
                </div>
                
                <form onsubmit={handleAddService} class="space-y-6">

                    <div>
                        <label for="removeServiceName" class="block text-sm font-medium text-gray-700">Suggested Service Name</label>
                        <select
                            id="removeServiceName"
                            bind:value={serviceName}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        >
                        {#each suggestedService as service}
                            <option value={service}>{service}</option>
                        {/each}
                            <option value="other">other</option>
                        </select>
                    </div>
                    {#if serviceName === "other"}
                    <div>
                        <label for="serviceName" class="block text-sm font-medium text-gray-700">Other Service Name</label>
                        <input
                            type="text"
                            id="serviceName"
                            bind:value={newServiceName}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        />
                    </div>
                    {/if}
                    

                    <div class="flex justify-end space-x-4">
                        <button
                            type="button"
                            onclick={closeAddServiceForm}
                            class="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                        >
                            Cancel
                        </button>
                        <button
                            type="submit"
                            class="px-4 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                        >
                            Add Service
                        </button>
                    </div>
                </form>
            </div>
        </div>
    {/if}

    {#if showRemoveServiceForm}
    <div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4">
        <div class="bg-white rounded-lg shadow-xl max-w-2xl w-full p-6">
            <div class="flex justify-between items-center mb-6">
                <h2 class="text-2xl font-semibold text-gray-900">Remove a Service</h2>
                <!-- svelte-ignore a11y_consider_explicit_label -->
                <button 
                    onclick={closeRemoveServiceForm}
                    class="text-gray-400 hover:text-gray-500"
                >
                    <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                </button>
            </div>
            
            <form onsubmit={() => handleRemoveService((document.getElementById("removeServiceName") as HTMLSelectElement).value)} class="space-y-6">
                <div>
                    <label for="removeServiceName" class="block text-sm font-medium text-gray-700">Service Name</label>
                    <select
                        id="removeServiceName"
                        bind:value={serviceName}
                        class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                        required
                    >
                    {#each venue.services as service}
                        <option value={service}>{service}</option>
                    {/each}
                    </select>
                </div>
                

                <div class="flex justify-end space-x-4">
                    <button
                        type="button"
                        onclick={closeRemoveServiceForm}
                        class="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                    >
                        Cancel
                    </button>
                    <button
                        type="submit"
                        class="px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                    >
                        Delete
                    </button>
                </div>
            </form>
        </div>
    </div>
    {/if}


    <div class="flex justify-between items-center mb-4 mt-16">
        <h1 class="text-2xl font-bold text-gray-900">Event Spaces</h1>
            <button 
                onclick={() => showCreateEventSpaceForm = true}
                class="bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 transition-colors"
            >
                Create Event Space
            </button>
    </div>
    {#if showCreateEventSpaceForm}
        <div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4">
            <div class="bg-white rounded-lg shadow-xl max-w-2xl w-full p-6">
                <div class="flex justify-between items-center mb-6">
                    <h2 class="text-2xl font-semibold text-gray-900">Create an Event Space</h2>
                    <!-- svelte-ignore a11y_consider_explicit_label -->
                    <button 
                        onclick={closeCreateEventSpaceForm}
                        class="text-gray-400 hover:text-gray-500"
                    >
                        <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                    </button>
                </div>
                
                <form onsubmit={handleCreateEventSpace} class="space-y-6">
                    <div>
                        <label for="eventSpaceName" class="block text-sm font-medium text-gray-700">Event Space Name</label>
                        <input
                            type="text"
                            id="eventSpaceName"
                            bind:value={eventSpaceName}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        />
                    </div>
                    <div>
                        <label for="eventSpaceSize" class="block text-sm font-medium text-gray-700">Event Space Size (ft²)</label>
                        <input
                            type="number"
                            id="eventSpaceSize"
                            bind:value={eventSpaceSize}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        />
                    </div>
                    <div>
                        <label for="eventSpaceCeilings" class="block text-sm font-medium text-gray-700">Ceiling Height (ft)</label>
                        <input
                            type="number"
                            id="eventSpaceCeilings"
                            bind:value={eventSpaceCeilings}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        />
                    </div>
                    

                    <div class="flex justify-end space-x-4">
                        <button
                            type="button"
                            onclick={closeCreateEventSpaceForm}
                            class="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                        >
                            Cancel
                        </button>
                        <button
                            type="submit"
                            class="px-4 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                        >
                            Create Event Space
                        </button>
                    </div>
                </form>
            </div>
        </div>
    {/if}
    {#if showEditEventSpaceForm}
        <div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4">
            <div class="bg-white rounded-lg shadow-xl max-w-2xl w-full p-6">
                <div class="flex justify-between items-center mb-6">
                    <h2 class="text-2xl font-semibold text-gray-900">Edit an Event Space</h2>
                    <!-- svelte-ignore a11y_consider_explicit_label -->
                    <button 
                        onclick={closeEditEventSpaceForm}
                        class="text-gray-400 hover:text-gray-500"
                    >
                        <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                    </button>
                </div>
                
                <form onsubmit={handleEditEventSpace} class="space-y-6">
                    <div>
                        <label for="editEventSpaceName" class="block text-sm font-medium text-gray-700">Event Space Name</label>
                        <input
                            type="text"
                            id="editEventSpaceName"
                            bind:value={currentEventSpace.name}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        />
                    </div>
                    <div>
                        <label for="editEventSpaceSize" class="block text-sm font-medium text-gray-700">Event Space Size (ft²)</label>
                        <input
                            type="number"
                            id="editEventSpaceSize"
                            bind:value={currentEventSpace.size}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        />
                    </div>
                    <div>
                        <label for="editEventSpaceCeilings" class="block text-sm font-medium text-gray-700">Ceiling Height (ft)</label>
                        <input
                            type="number"
                            id="editEventSpaceCeilings"
                            bind:value={currentEventSpace.ceilings}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        />
                    </div>
                    

                    <div class="flex justify-end space-x-4">
                        <button
                            type="button"
                            onclick={closeEditEventSpaceForm}
                            class="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                        >
                            Cancel
                        </button>
                        <button
                            type="submit"
                            class="px-4 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                        >
                            Edit Event Space
                        </button>
                    </div>
                </form>
            </div>
        </div>
    {/if}
    <!-- Event Spaces List -->
    <div class="mt-2">
        {#if eventSpaces.size === 0}
            <div class="text-center py-12 bg-gray-50 rounded-lg">
                <p class="text-gray-500">No event spaces created yet. Click "Create Event Space" to get started.</p>
            </div>
        {:else}
            <div class="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
                {#each eventSpaces.entries() as [eventSpaceId, eventSpace]}
                    <div class="bg-white rounded-lg shadow p-6">
                        <div class="flex justify-between items-start mb-4">
                            <h3 class="text-xl font-bold text-gray-900">{eventSpace.name}</h3>
                                <div class="flex space-x-2">
                                    <!-- svelte-ignore a11y_consider_explicit_label -->
                                    <!-- Edit button -->
                                    <button 
                                        onclick={() => openEditEventSpaceForm(eventSpace)}
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
                                        onclick={() => handleRemoveEventSpace(eventSpace.id)}
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
                        <!-- Event Cards -->
                        <div class="space-y-2 text-sm text-gray-600">
                            <p><span class="font-medium">Size (ft²):</span> {eventSpace.size}</p>
                            <p><span class="font-medium">Ceiling Height (ft):</span> {eventSpace.ceilings}</p>
                            <h1 class="text-lg font-semibold text-gray-800">Space Setups: 
                                <button onclick={() => openAddSetupForm(eventSpace)}
                                aria-label="Add Service"
                                class="bg-indigo-600 text-white px-2 py-1 rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 transition-colors">
                                <svg 
                                    xmlns="http://www.w3.org/2000/svg" 
                                    class="h-4 w-4" 
                                    fill="none" 
                                    viewBox="0 0 24 24" 
                                    stroke="currentColor"
                                >
                                    <path 
                                        stroke-linecap="round" 
                                        stroke-linejoin="round" 
                                        stroke-width="2" 
                                        d="M12 4 V20 M4 12 H20" 
                                    />
                            </button>
                            <button onclick={() => openRemoveSetupForm(eventSpace)}
                                aria-label="Remove Service"
                                class="bg-red-600 text-white px-2 py-1 rounded-md hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 transition-colors">
                                <svg 
                                    xmlns="http://www.w3.org/2000/svg" 
                                    class="h-4 w-4" 
                                    fill="none" 
                                    viewBox="0 0 24 24" 
                                    stroke="currentColor"
                                >
                                    <path 
                                        stroke-linecap="round" 
                                        stroke-linejoin="round" 
                                        stroke-width="2" 
                                        d="M4 12 H20" 
                                    />
                                </svg>
                            </button></h1>
                            <div class="flex flex-wrap gap-2 text-gray-700 mb-2 mt-2">
                                {#each eventSpace.spaceSetups.entries() as [currentSetupName, currentSetupCapacity]}
                                <p><span class="font-semibold bg-gray-200 text-gray-900 px-3 py-1 rounded-lg text-sm">{currentSetupName} | {currentSetupCapacity} people </span></p>
                                {/each}
                            </div>
                        </div>
                    </div>
                {/each}
            </div>
        {/if}
    </div>

    {#if showAddSetupForm}
        <div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4">
            <div class="bg-white rounded-lg shadow-xl max-w-2xl w-full p-6">
                <div class="flex justify-between items-center mb-6">
                    <h2 class="text-2xl font-semibold text-gray-900">Add a Setup</h2>
                    <!-- svelte-ignore a11y_consider_explicit_label -->
                    <button 
                        onclick={closeAddSetupForm}
                        class="text-gray-400 hover:text-gray-500"
                    >
                        <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                    </button>
                </div>
                
                <form onsubmit={handleAddSetup} class="space-y-6">
                    <div>
                        <label for="setupName" class="block text-sm font-medium text-gray-700">Setup Name</label>
                        <input
                            type="text"
                            id="setupName"
                            bind:value={setupName}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        />
                    </div>
                    <div>
                        <label for="setupCapacity" class="block text-sm font-medium text-gray-700">Capacity</label>
                        <input
                            type="number"
                            id="setupCapacity"
                            bind:value={setupCapacity}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        />
                    </div>
                    

                    <div class="flex justify-end space-x-4">
                        <button
                            type="button"
                            onclick={closeAddSetupForm}
                            class="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                        >
                            Cancel
                        </button>
                        <button
                            type="submit"
                            class="px-4 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                        >
                            Add Setup
                        </button>
                    </div>
                </form>
            </div>
        </div>
    {/if}
    {#if showRemoveSetupForm}
        <div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4">
            <div class="bg-white rounded-lg shadow-xl max-w-2xl w-full p-6">
                <div class="flex justify-between items-center mb-6">
                    <h2 class="text-2xl font-semibold text-gray-900">Remove a Setup</h2>
                    <!-- svelte-ignore a11y_consider_explicit_label -->
                    <button 
                        onclick={closeRemoveSetupForm}
                        class="text-gray-400 hover:text-gray-500"
                    >
                        <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                    </button>
                </div>
                
                <form onsubmit={handleRemoveSetup} class="space-y-6">
                    <div>
                        <label for="setupName" class="block text-sm font-medium text-gray-700">Setup Name</label>
                        <select
                            id="setupName"
                            bind:value={setupName}
                            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                            required
                        >
                        {#each currentEventSpace.spaceSetups.entries() as [removeSetupName, removeSetupCapacity]}
                            <option>{removeSetupName}</option>
                        {/each}
                        </select>
                    </div>
                    

                    <div class="flex justify-end space-x-4">
                        <button
                            type="button"
                            onclick={closeRemoveSetupForm}
                            class="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                        >
                            Cancel
                        </button>
                        <button
                            type="submit"
                            class="px-4 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                        >
                            Remove Setup
                        </button>
                    </div>
                </form>
            </div>
        </div>
    {/if}
</div>
{/if}