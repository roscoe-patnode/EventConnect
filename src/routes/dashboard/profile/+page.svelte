<script lang="ts">
    import { onMount } from 'svelte';
    import { supabase } from '$lib/supabaseClient';

    // Define the user type according to Supabase AuthUser structure
    type User = {
        id: string;
        first_name: string | null;
        last_name: string | null;
        email: string | null;
        phone: string | null;
        role: string | null;
    } | null;

    let user: User = null;

    onMount(async () => {
    const { data, error } = await supabase.auth.getUser(); // Fetch the authenticated user
    if (error) {
        console.error("Error fetching user:", error);
    } else {
        // Fetch additional profile data from the 'Profiles' table using the user id
        const { data: profileData, error: profileError } = await supabase
            .from('Profiles') // Make sure to match the table name exactly: 'Profiles'
            .select('id, first_name, last_name, email, phone, role')
            .eq('id', data.user?.id) // Match the user id
            .single(); // Fetch a single row

        if (profileError) {
            console.error("Error fetching profile:", profileError);
        } else {
            user = profileData
                ? {
                    id: profileData.id,
                    first_name: profileData.first_name ?? null,
                    last_name: profileData.last_name ?? null,
                    email: profileData.email ?? null,
                    phone: profileData.phone ?? null,
                    role: profileData.role ?? null
                }
                : null;
        }
    }
});

</script>

<h1 class="text-2xl font-semibold text-center mt-6">Profile</h1>

<div class="flex justify-center items-center mt-8">
    {#if user}
        <div class="w-full sm:w-3/4 lg:w-1/2 p-6 bg-white shadow-md rounded-lg">
            <div class="space-y-4">
                <p><strong>Full Name:</strong> {user.first_name} {user.last_name}</p>
                <p><strong>Email:</strong> {user.email}</p>
                <p><strong>Phone:</strong> {user.phone}</p>
                <p><strong>Role:</strong> {user.role}</p>
                <p><strong>UID:</strong> {user.id}</p>
            </div>
        </div>
    {:else}
        <p>No profile information found.</p>
    {/if}
</div>