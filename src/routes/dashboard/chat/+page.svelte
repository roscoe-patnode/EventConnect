<script lang="ts">
    import Message from './Message.svelte';
    import { onMount } from 'svelte';
    
    // State variables with Svelte 5 $state syntax
    let messages = $state<Array<{content: string, alignment: 'left' | 'right', time: Date}>>([]);
    let newMessage = $state('');
    
    // Sample data to replace with actual data fetch
    onMount(() => {
        // example data - real app will fetch messages from a database
        // messages = [
        //     {
        //         content: "Hi there! How can I help with your event?",
        //         alignment: "left",
        //         time: new Date(Date.now() - 3600000) // 1 hour ago
        //     },
        //     {
        //         content: "I'm looking for information about venue management",
        //         alignment: "right",
        //         time: new Date(Date.now() - 3500000) // 58 minutes ago
        //     },
        //     {
        //         content: "Sure. What size is the venue ?",
        //         alignment: "left",
        //         time: new Date(Date.now() - 3400000) // 56 minutes ago
        //     }
        // ];
    });
    
    // Function to send a message
    function sendMessage() {
        if (!newMessage.trim()) return;
        
        // Add the new message to the messages array
        messages = [...messages, {
            content: newMessage,
            alignment: "right", // Current user's messages are aligned right
            time: new Date()
        }];
        
        // Clear the input field
        newMessage = '';
        
        // Scroll to the bottom of the chat
        setTimeout(() => {
            const chatWindow = document.getElementById('chat-window');
            if (chatWindow) {
                chatWindow.scrollTop = chatWindow.scrollHeight;
            }
        }, 50);
        
        // send the message to your backend 
    }
    
    // Handle Enter key press
    function handleKeyPress(event: KeyboardEvent) {
        if (event.key === 'Enter') {
            sendMessage();
        }
    }
</script>


<!-- Chat container -->
<div class="flex flex-col items-center justify-center w-[600px] mx-auto mt-4">
    <!-- chat window -->
    <div id="chat-window" class="w-full h-[500px] bg-slate-800 rounded-md p-4 overflow-y-auto flex flex-col space-y-4">
        {#each messages as message}
            <Message 
                content={message.content}
                alignment={message.alignment}
                time={message.time}
            />
        {/each}
    </div>
    
    <!-- message preview and send button container-->
    <div class="flex items-center w-full space-x-2 mt-2">
        <!-- Message preview -->
        <div class="w-[500px] bg-zinc-200 rounded-md p-2">
            <input
                class="w-full bg-transparent outline-none"
                type="text"
                id="messagePreview"
                placeholder="Send a chat"      
                bind:value={newMessage}
                onkeydown={handleKeyPress}
                required
            >
        </div>
        <!-- Send button -->
        <button
            class="grow bg-slate-400 rounded-md p-2 cursor-pointer hover:bg-slate-500 text-white font-medium"
            type="button"
            onclick={sendMessage}
        >
            Send
        </button>
    </div>
</div>