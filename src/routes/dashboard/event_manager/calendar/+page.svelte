<!-- +page.svelte -->
<script lang="ts">
    import { onMount } from 'svelte';
    import Calendar from '$lib/components/Calendar.svelte';
    import { supabase } from '$lib/supabaseClient';
      
    // Types
    type Event = {
        id: string;
        name: string;
        dates: string[];  // Array of date strings
        venue_id: string;
        venue_name?: string; // Add this new field
    };
      
    type Profile = {
        id: string;
        role: string; // 'event_manager'
        venue_admin_id?: string;
    };
      
    type Venue = {
        id: string;
        name: string;
        venue_admin_id: string;
    };
      
    // State variables
    let isLoading = $state(true);
    let error = $state<string | null>(null);
    let events = $state<Event[]>([]);
    let currentUser = $state<Profile | null>(null);
    let userVenue = $state<Venue | null>(null);
      
    // Fetch the current user data
    async function fetchUserProfile() {
      try {
        const { data: { user } } = await supabase.auth.getUser();
          
        if (!user) throw new Error('Not authenticated');
        
        // Get user profile from Profiles table
        const { data: profileData, error: profileError } = await supabase
          .from('Profiles') 
          .select('*')
          .eq('id', user.id)
          .single();
        
        if (profileError) {
          console.error('Profile error:', profileError);
          error = 'Failed to load user profile';
          return null;
        }
        
        if (!profileData) {
          error = 'User profile not found';
          return null;
        }
        
        
        // Check if the role field exists and handle different capitalization or formatting
        // Use optional chaining and nullish coalescing for safety
        const role = profileData.role?.toLowerCase?.() ?? '';
        console.log('Normalized user type:', role);
        
        if (role !== 'event_manager') {
          console.warn('User is not an event manager:', role);
          error = 'Only event managers can access this page';
          return null;
        }
        
        currentUser = profileData;
        return profileData;
  
      } catch (err) {
        console.error('Error fetching user profile:', err);
        error = err.message || 'Failed to load user data';
        return null;
      }
    }
  
    // Fetch venue associated with the venue admin
    async function fetchUserVenue(profile: Profile) {
      try {
        // First, let's try to find a venue for this user
        const { data: venueData, error: venueError } = await supabase
          .from('Venues')
          .select('*')
          .eq('venue_admin_id', profile.id)
          .single();
        
        if (venueError) {
          console.log('No venue found for this user, fetching first available venue');
          
          // If that fails, get any venue
          const { data: firstVenue, error: firstVenueError } = await supabase
            .from('Venues')
            .select('*')
            .limit(1)
            .single();
          
          if (firstVenueError) {
            console.error('Failed to fetch any venue:', firstVenueError);
            throw firstVenueError;
          }
          
          if (!firstVenue) throw new Error('No venues found in the database');
      
          userVenue = firstVenue;
          return firstVenue;
        }
        
        if (!venueData) throw new Error('No venue found for this user');
        
        userVenue = venueData;
        return venueData;
  
      } catch (err) {
        console.error('Error fetching venue:', err);
        error = err.message || 'Failed to load venue data';
        return null;
      }
    }
      
    // Fetch events for the venue
    async function fetchVenueEvents(venue: Venue) {
      try {
        const { data: eventData, error: eventError } = await supabase
          .from('Events')  
          .select('*')
          .eq('venue_id', venue.id)
          .order('title', { ascending: true }) 
        
        if (eventError) throw eventError;
        
        // Transform the data to match the expected format in Calendar.svelte
        const transformedEvents = eventData?.map(event => ({
          id: event.id,
          name: event.title, // Map 'title' from DB to 'name' for Calendar component
          dates: event.dates,
          venue_id: event.venue_id
        })) || [];
        
        events = transformedEvents;
        console.log(`Loaded ${events.length} events for venue ${venue.id}`);
  
      } catch (err) {
        console.error('Error fetching events:', err);
        error = err.message || 'Failed to load event data';
      }
    }

    // Fetch events assigned to this event manager
    async function fetchEventManagerEvents(profile: Profile) {
        try {
            // First, get the list of event IDs assigned to this event manager
            const { data: eventAssignments, error: assignmentError } = await supabase
            .from('EventManagerEventsList')
            .select('event_id')
            .eq('event_manager_id', profile.id);
            
            if (assignmentError) {
            console.error('Error fetching event assignments:', assignmentError);
            error = 'Failed to load your assigned events';
            return;
            }
            
            if (!eventAssignments || eventAssignments.length === 0) {
            console.log('No events assigned to this event manager');
            events = [];
            return;
            }
            
            // Extract the event IDs from the assignments
            const eventIds = eventAssignments.map(assignment => assignment.event_id);
            
            // Now fetch the full details of these events
            const { data: eventData, error: eventError } = await supabase
            .from('Events')
            .select(`
                id,
                title,
                dates,
                venue_id,
                Venues (
                id,
                name
                )
            `)
            .in('id', eventIds)
            .order('title', { ascending: true });
            
            if (eventError) {
                console.error('Error fetching events:', eventError);
                error = 'Failed to load event details';
                return;
            }
            
            // Transform the data to match the expected format in Calendar.svelte
            // and include venue name for each event
            const transformedEvents = eventData?.map(event => ({
                id: event.id,
                name: event.title,
                dates: event.dates,
                venue_id: event.venue_id,
                venue_name: event.Venues?.name || 'Unknown Venue'
            })) || [];
            
            events = transformedEvents;
            console.log(`Loaded ${events.length} events for event manager ${profile.id}`);
            
            // If there are events, set the userVenue to the venue of the first event
            if (events.length > 0 && events[0].venue_id) {
                const { data: venueData } = await supabase
                    .from('Venues')
                    .select('*')
                    .eq('id', events[0].venue_id)
                    .single();
                
                if (venueData) {
                    userVenue = venueData;
                }
            }
            
        } catch (err) {
            console.error('Error fetching event manager events:', err);
            error = err.message || 'Failed to load event data';
        }
    }
      
    // Load all data on component mount
    onMount(async () => {
        try {
            const profile = await fetchUserProfile();
            if (!profile) {
            isLoading = false;
            return;
            }
            
            // Use the new function to fetch events for this event manager
            await fetchEventManagerEvents(profile);
            
            isLoading = false;
        } catch (err) {
            console.error('Error in data loading chain:', err);
            error = err.message || 'An unexpected error occurred';
            isLoading = false;
        }
    });
</script>
    
<div class="calendar-page">
    <header>
        <h1>Event Manager Calendar</h1>
        <div class="user-info">
            {#if currentUser}
                <p>Event Manager: {currentUser.first_name}</p>
            {/if}
        </div>
    </header>
    
    {#if isLoading}
        <div class="loading">
            <p>Loading calendar...</p>
            <!-- Could add a spinner here -->
        </div>
    {:else if error}
        <div class="error">
            <p>{error}</p>
            <button onclick={() => window.location.reload()}>Retry</button>
        </div>
    {:else}
        <Calendar {events} />
        
        <!-- Event Manager specific information section -->
        <div class="events-summary">
            <h3>Your Assigned Events</h3>
            {#if events.length === 0}
                <p>No events are currently assigned to you.</p>
            {:else}
                <div class="events-grid">
                    {#each events as event}
                        <div class="event-card">
                            <h4>{event.name}</h4>
                            <p class="venue-name">Venue: {event.venue_name}</p>
                            <p class="dates-info">
                                {#if event.dates.length === 1}
                                    <span>Date: {new Date(event.dates[0]).toLocaleDateString()}</span>
                                {:else}
                                    <span>Dates: {event.dates.length} days</span>
                                    <span class="date-range">
                                        {new Date(event.dates[0]).toLocaleDateString()} - 
                                        {new Date(event.dates[event.dates.length - 1]).toLocaleDateString()}
                                    </span>
                                {/if}
                            </p>
                        </div>
                    {/each}
                </div>
            {/if}
        </div>
    {/if}
</div>
    
<style>

    .calendar-page {
        width: 100%;
        max-width: 1200px;
        margin: 0 auto;
        padding: 20px;
    }
      
    header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 20px;
        flex-wrap: wrap;
    }
    
    h1 {
        font-size: 28px;
        margin: 0;
    }
    
    .loading, .error {
        text-align: center;
        padding: 40px;
        background-color: #f8f9fa;
        border-radius: 8px;
        margin-top: 20px;
    }
      
    .error {
        color: #dc3545;
    }
    
    .error button {
        background-color: #6c757d;
        color: white;
        border: none;
        border-radius: 4px;
        padding: 8px 16px;
        margin-top: 10px;
        cursor: pointer;
    }

    .user-info {
        margin: 0;
        color: #6c757d;
    }

    .events-summary {
        margin-top: 30px;
        padding: 20px;
        background-color: #f8f9fa;
        border-radius: 8px;
    }

    .events-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
        gap: 15px;
        margin-top: 15px;
    }

    .event-card {
        padding: 15px;
        border-radius: 8px;
        background-color: white;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }

    .event-card h4 {
        margin-top: 0;
        margin-bottom: 10px;
        color: #4a90e2;
    }

    .venue-name {
        font-weight: 500;
        margin-bottom: 8px;
    }

    .dates-info {
        display: flex;
        flex-direction: column;
        font-size: 14px;
        color: #6c757d;
    }

    .date-range {
        margin-top: 5px;
    }

</style>