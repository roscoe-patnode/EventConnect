<script lang="ts">
    import { onMount } from 'svelte';
    import { supabase } from '$lib/supabaseClient';

    type User = {
        id: string;
        first_name: string | null;
        last_name: string | null;
        email: string | null;
        phone: string | null;
        role: string | null;
    } | null;

    let user: User = null;
    let editing = false;
    let newPhone = "";

    onMount(async () => {
        const { data, error } = await supabase.auth.getUser();
        if (error) {
            console.error("Error fetching user:", error);
        } else {
            const { data: profileData, error: profileError } = await supabase
                .from('Profiles')
                .select('id, first_name, last_name, email, phone, role')
                .eq('id', data.user?.id)
                .single();

            if (profileError) {
                console.error("Error fetching profile:", profileError);
            } else {
                user = profileData;
                if (user?.phone) {
                    user.phone = formatPhoneNumber(user.phone);
                }
            }
        }
    });

    function formatPhoneNumber(phone: string): string {
        return phone.replace(/(\d{3})(\d{3})(\d{4})/, "$1-$2-$3");
    }

    function handlePhoneInput(event: Event) {
        let input = (event.target as HTMLInputElement).value.replace(/\D/g, "");
        if (input.length > 10) input = input.slice(0, 10);
        newPhone = input.replace(/(\d{3})(\d{3})(\d{4})/, "$1-$2-$3");
    }

    async function updatePhone() {
        const rawPhone = newPhone.replace(/\D/g, "");
        if (!/^[0-9]{10}$/.test(rawPhone)) {
            alert("Please enter a valid 10-digit phone number.");
            return;
        }

        const { error } = await supabase
            .from('Profiles')
            .update({ phone: rawPhone })
            .eq('id', user?.id);

        if (error) {
            console.error("Error updating phone number:", error);
        } else {
            if (user) user.phone = formatPhoneNumber(rawPhone);
            editing = false;
        }
    }
</script>

<h1 class="text-2xl font-semibold text-center mt-6">Profile</h1>

<div class="flex justify-center items-center mt-8">
    {#if user}
        <div class="w-full sm:w-3/4 lg:w-1/2 p-6 bg-white shadow-md rounded-lg">
            <div class="space-y-4">
                <p><strong>Full Name:</strong> {user.first_name} {user.last_name}</p>
                <p><strong>Email:</strong> {user.email}</p>
                <p>
                    <strong>Phone:</strong> {#if editing}
                        <input type="text" bind:value={newPhone} on:input={handlePhoneInput} placeholder="Enter new phone number" class="border rounded p-1" />
                        <button on:click={updatePhone} class="ml-2 px-2 py-1 bg-green-500 text-white rounded">Save</button>
                        <button on:click={() => editing = false} class="ml-2 px-2 py-1 bg-gray-400 text-white rounded">Cancel</button>
                    {:else}
                        {user.phone} 
                        <button on:click={() => { editing = true; newPhone = user.phone?.replace(/\D/g, '') || ''; }} class="ml-2 px-2 py-1 bg-blue-500 text-white rounded">Edit</button>
                    {/if}
                </p>
                <p><strong>Role:</strong> {user.role}</p>
                <p><strong>UID:</strong> {user.id}</p>
            </div>
        </div>
    {:else}
        <p>No profile information found.</p>
    {/if}
</div>