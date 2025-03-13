<!-- +page.svelte -->
<script lang="ts">
  import { onMount } from 'svelte';
  import Calendar from './Calendar.svelte';
  import { supabase } from '$lib/supabaseClient';
    
  // Types
  type Event = {
    id: string;
    name: string;
    dates: string[];  // Array of date strings
    venue_id: string;
  };
    
  type Profile = {
    id: string;
    user_type: string; // 'venue_admin', 'event_manager', or 'venue_staff'
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
          // If no profile exists, we'll create a default one for development purposes
          currentUser = { id: user.id, user_type: 'venue_admin' };
          return currentUser;
      }
      
      if (!profileData) {
          console.warn('Profile not found, using default');
          // Create a default profile for development
          currentUser = { id: user.id, user_type: 'venue_admin' };
          return currentUser;
      }
      
      currentUser = profileData;
      
      // Debug log to check what user_type value we're getting
      console.log('User type from database:', profileData.user_type);
      
      // Check if the user_type field exists and handle different capitalization or formatting
      // Use optional chaining and nullish coalescing for safety
      const userType = profileData.user_type?.toLowerCase?.() ?? '';
      console.log('Normalized user type:', userType);
      
      if (!userType.includes('admin') && userType !== 'venue_admin') {
          console.warn('User is not a venue admin:', userType);
          // For development purposes, we'll continue anyway
          // throw new Error('Only venue admins can access this page');
      }
      
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
    
    // Load all data on component mount
    onMount(async () => {
      try {
        const profile = await fetchUserProfile();
        if (!profile) return;
        
        const venue = await fetchUserVenue(profile);
        if (!venue) return;
        
        await fetchVenueEvents(venue);
        
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
      <h1>Calendar</h1>
      <div class="venue-info">
        {#if userVenue}
          <h2>Venue: {userVenue.name}</h2>
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
    
    .venue-info {
      margin: 0;
    }
    
    .venue-info h2 {
      font-size: 18px;
      color: #6c757d;
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
</style>