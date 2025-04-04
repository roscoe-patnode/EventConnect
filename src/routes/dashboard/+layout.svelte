<script lang="ts">
    import { onMount } from 'svelte';
    import { supabase } from '$lib/supabaseClient';
    import { goto } from '$app/navigation';
    
    let { children } = $props();
    let userRole = $state<string | null>(null);
    let loading = $state(true);

    onMount(async () => {
        try {
            const { data: { user } } = await supabase.auth.getUser();
            
            if (user) {
                // Fetch user's role from profiles table
                const { data: profileData, error } = await supabase
                    .from('Profiles')
                    .select('role')
                    .eq('id', user.id)
                    .single();

                if (error) throw error;
                userRole = profileData.role;
                
                // Updated redirection logic:
                const currentPath = window.location.pathname;
                if (userRole === 'event_manager' && (currentPath === '/dashboard' || currentPath === '/dashboard/event_manager')) {
                    goto('/dashboard/event_manager/events');
                } else if (userRole === 'venue_admin' && (currentPath === '/dashboard' || currentPath === '/dashboard/venue_admin')) {
                    goto('/dashboard/venue_admin/venue');
                } else if (userRole === 'venue_staff' && (currentPath === '/dashboard' || currentPath === '/dashboard/venue_staff')) {
                    goto('/dashboard/venue_staff/tickets');
                }
            } else {
                // No user is signed in, redirect to home page
                goto('/');
            }
        } catch (error) {
            console.error('Error fetching user role:', error);
            goto('/');
        } finally {
            loading = false;
        }
    });



    async function handleSignOut() {
        try {
            const { error } = await supabase.auth.signOut();
            if (error) throw error;
            goto('/');
        } catch (error) {
            console.error('Error signing out:', error);
        }
    }

    async function goProfile() {
        goto('/profile')
    }


    // Navigation items based on role
    const navItems:any = {
        event_manager: [
            { href: "/dashboard/event_manager/events", label: "My Events" },
            { href: "/dashboard/event_manager/tickets", label: "Tickets" },
            { href: "/dashboard/event_manager/calendar", label: "Calendar" }
        ],
        venue_admin: [
            { href: "/dashboard/venue_admin/venue", label: "My Venue" },
            { href: "/dashboard/venue_admin/events", label: "My Events" },
            { href: "/dashboard/venue_admin/calendar", label: "Calendar" },
            // { href: "/dashboard/chat", label: "Chat" }
        ],
        venue_staff: [
            // { href: "/dashboard/venue_staff/schedule", label: "Schedule" },
            { href: "/dashboard/venue_staff/tickets", label: "Tickets" },
        ]
    };

</script>

<!-- might have to change staff user role in #if -->
<div class="min-h-screen flex flex-col">
    <nav class="w-full transition-all duration-300 bg-white shadow-sm">
        <div class="max-w-7xl mx-auto px-8">
            <div class="flex justify-between items-center h-16">
                <!-- Logo side -->
                <div class="flex-shrink-0">
                    <a 
                      href={
                        userRole === 'event_manager' 
                          ? '/dashboard/event_manager/events' 
                          : userRole === 'venue_admin'
                            ? '/dashboard/venue_admin/venue'
                            : userRole === 'venue_staff'
                              ? '/dashboard/venue_staff/tickets'
                              : '/dashboard'
                      }
                      class="flex items-center"
                    >
                      <span class="text-xl font-bold text-indigo-600">
                        {#if userRole}
                          {userRole === 'event_manager' ? 'Event Dashboard' :
                           userRole === 'venue_admin' ? 'Administrator Dashboard' :
                           'Staff Dashboard'}
                        {:else}
                          Dashboard
                        {/if}
                      </span>
                    </a>
                  </div>
                  

                <!-- Navigation side -->
                <div>
                    <div class="flex items-center space-x-6">
                        {#if loading}
                            <div class="animate-pulse h-4 w-20 bg-gray-200 rounded"></div>
                        {:else if userRole}
                            <!-- Role-specific navigation -->
                            {#each navItems[userRole] as item}
                                <a 
                                    href={item.href}
                                    class="px-3 py-2 rounded-md text-sm font-medium text-gray-700 hover:bg-indigo-50 hover:text-indigo-600 transition-colors"
                                >
                                    {item.label}
                                </a>
                            {/each}
                            
                            <!-- User menu and logout -->
                            <div class="flex items-center space-x-4">
                                <a 
                                    href="/dashboard/profile"
                                    class="px-3 py-2 rounded-md text-sm font-medium text-gray-700 hover:bg-indigo-50 hover:text-indigo-600 transition-colors"
                                >
                                    Profile
                                </a>
                                <button 
                                    onclick={handleSignOut}
                                    class="px-3 py-2 rounded-md text-sm font-medium text-red-600 hover:bg-red-50 transition-colors"
                                >
                                    Sign Out
                                </button>
                            </div>
                        {:else}
                            <!-- Default navigation for non-authenticated users -->
                            <a href="/LogInSignUp" class="px-3 py-2 rounded-md text-sm font-medium text-indigo-600 hover:bg-indigo-50 transition-colors">Login/SignUp</a>
                            <a href="/AboutUs" class="px-3 py-2 rounded-md text-sm font-medium text-gray-700 hover:bg-indigo-50 hover:text-indigo-600 transition-colors">About us</a>
                            <a href="/Pricing" class="px-3 py-2 rounded-md text-sm font-medium text-gray-700 hover:bg-indigo-50 hover:text-indigo-600 transition-colors">Pricing</a>
                        {/if}
                    </div>
                </div>
            </div>
        </div>
    </nav>

    <!-- Content -->
    <main class="flex-grow flex-col justify-center items-center">
        {@render children()}
    </main>
</div>