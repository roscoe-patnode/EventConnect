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
                    .from('profiles')
                    .select('role')
                    .eq('id', user.id)
                    .single();

                if (error) throw error;
                userRole = profileData.role;
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

    // Navigation items based on role
    const navItems:any = {
        event_planner: [
            { href: "/dashboard/planner", label: "My Events" },
            { href: "/dashboard/planner/bookings", label: "Book Facility" },
            { href: "/dashboard/planner/calendar", label: "Calendar" }
        ],
        facility_owner: [
            { href: "/dashboard/owner/facilities", label: "My Facilities" },
            { href: "/dashboard/owner/bookings", label: "Bookings" },
            { href: "/dashboard/owner/analytics", label: "Analytics" }
        ],
        staff_member: [
            { href: "/dashboard/staff/tasks", label: "Tasks" },
            { href: "/dashboard/staff/schedule", label: "Schedule" },
            { href: "/dashboard/staff/reports", label: "Reports" }
        ]
    };

</script>

<div class="min-h-screen flex flex-col">
    <nav class="w-full transition-all duration-300 bg-white shadow-sm">
        <div class="max-w-7xl mx-auto px-8">
            <div class="flex justify-between items-center h-16">
                <!-- Logo side -->
                <div class="flex-shrink-0">
                    <a href="/" class="flex items-center">
                        <span class="text-xl font-bold text-indigo-600">
                            {#if userRole}
                                {userRole === 'event_planner' ? 'Event Dashboard' :
                                 userRole === 'facility_owner' ? 'Facility Dashboard' :
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
                                    href="/profile" 
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