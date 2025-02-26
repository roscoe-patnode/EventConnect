<!-- Message.svelte -->
<script lang="ts">
    
    // Define the props for the component
    export let content: string;
    export let alignment: 'left' | 'right';
    export let time: Date;

    // Format the time to show only hours and minutes
    function formatTime(date: Date): string {
        return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    }

    // Compute classes based on alignment
    $: messageClasses = alignment === 'right'
        ? 'bg-indigo-100 text-gray-800'
        : 'bg-gray-200 text-gray-800';
    
    $: containerClasses = alignment === 'right'
        ? 'flex justify-end'
        : 'flex justify-start';
</script>

<div class={containerClasses}>
    <div class="{messageClasses} rounded-lg px-4 py-2 max-w-xs sm:max-w-md">
        <div>{content}</div>
        <div class="text-xs text-gray-500 mt-1 text-right">
            {formatTime(time)}
        </div>
    </div>
</div>