<script lang="ts">
    import { supabase } from "$lib/supabaseClient";
    import { onMount } from 'svelte';

    // Variables used to check User Role
    let loading = $state(true);
    let userRole = $state("");

    async function fetchRole() {
        const { data: userData } = await supabase.auth.getUser();
        const { data: userRoleData, error } = await supabase
            .from("Profiles")
            .select("role")
            .eq("id", userData.user!.id);
        if (error) throw error;
            userRole = userRoleData[0].role;
    }

    onMount(async () => {
        await fetchRole();
        loading = false;
    });
</script>
<!-- Check if User has the Permissions to View Page -->
{#if userRole !== 'venue_staff' && !loading}
    <div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4">
        <div class="fixed inset-0 bg-gray-900 bg-opacity-80 flex items-center justify-center p-6">
            <div class="bg-white rounded-2xl shadow-xl p-6 max-w-md text-center">
                <h2 class="text-2xl font-semibold text-gray-800">Access Denied</h2>
                <p class="text-gray-600 mt-2">You do not have permission to view this page.</p>
            </div>
        </div>
    </div>
{:else}
    <div class="max-w-5xl mx-auto">
        <div class=" h-full w-full text-zinc-800 text-2xl ">Venue Staff</div>
    </div>
{/if}