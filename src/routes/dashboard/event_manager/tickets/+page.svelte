<script lang="ts">
    import { supabase } from '$lib/supabaseClient';
    import { onMount } from 'svelte';
  
    // Bind form fields
    let event_id = '';
    let service = '';
    let priority = 'Medium'; // default value, e.g., Medium
    let description = '';
  
    // Assume current user's profile id is retrieved from session context.
    // Replace this with your actual logic to get the logged-in user's profile id.
    let currentUserId = 'your-current-user-id'; 
  
    async function createTicket() {
      // Construct the new ticket payload
      const newTicket = {
        event_id,
        ticket_owner: currentUserId,
        service,
        priority,
        status: 'Pending', // New tickets start as Pending
        description,
        date_created: new Date().toISOString()
      };
  
      // Insert the new ticket into Supabase
      const { data, error } = await supabase
        .from('Tickets')
        .insert([newTicket]);
  
      if (error) {
        console.error('Error creating ticket:', error);
        alert('Failed to create ticket. Please try again.');
      } else {
        console.log('Ticket created successfully:', data);
        alert('Ticket created!');
        // Optionally, clear the form:
        event_id = service = description = '';
        priority = 'Medium';
      }
    }
  </script>
  
  <h1>Create a Service Request Ticket</h1>
  
  <form on:submit|preventDefault={createTicket}>
    <div>
      <label for="event">Event ID:</label>
      <input id="event" type="text" bind:value={event_id} placeholder="Enter Event ID" required />
    </div>
  
    <div>
      <label for="service">Service Type:</label>
      <input id="service" type="text" bind:value={service} placeholder="e.g., Lighting, Catering" required />
    </div>
  
    <div>
      <label for="priority">Priority:</label>
      <select id="priority" bind:value={priority}>
        <option value="Low">Low</option>
        <option value="Medium">Medium</option>
        <option value="High">High</option>
      </select>
    </div>
  
    <div>
      <label for="description">Description:</label>
      <textarea id="description" bind:value={description} placeholder="Provide details about your service request"></textarea>
    </div>
  
    <button type="submit">Submit Ticket</button>
  </form>
  