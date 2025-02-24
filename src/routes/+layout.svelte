<script lang="ts">
	import '../app.css';
	import { onMount } from 'svelte';
	import { page } from "$app/state";
	
	let { children } = $props();
	let scrolled = $state(false);
	
	onMount(() => {
	  const handleScroll = () => {
		scrolled = window.scrollY > 10;
	  };
	  
	  window.addEventListener('scroll', handleScroll);
	  
	  return () => {
		window.removeEventListener('scroll', handleScroll);
	  };
	});
  </script>

  {#if page.route.id?.startsWith("/dashboard") === false}
  <div class="min-h-screen flex flex-col">
	<!-- Static Navbar (not fixed) -->
	<nav class={`w-full transition-all duration-300 ${scrolled ? 'bg-white shadow-md py-2' : 'bg-transparent py-4'}`}>
	  <div class="max-w-7xl mx-auto px-8">
		<div class="flex justify-between items-center h-16">
		  <!-- Logo -->
		  <div class="flex-shrink-0">
			<a href="/" class="flex items-center">
			  <span class="text-xl font-bold text-indigo-600">Logo</span>
			</a>
		  </div>
		  
		  <!-- Desktop Navigation -->
		  <div>
			<div class="flex items-center space-x-6">
			  <a href="/LogInSignUp" class="px-3 py-2 rounded-md text-sm font-medium text-indigo-600 hover:bg-indigo-50 transition-colors">Login/SignUp</a>
			  <a href="/AboutUs" class="px-3 py-2 rounded-md text-sm font-medium text-gray-700 hover:bg-indigo-50 hover:text-indigo-600 transition-colors">About us</a>
			  <a href="/Pricing" class="px-3 py-2 rounded-md text-sm font-medium text-gray-700 hover:bg-indigo-50 hover:text-indigo-600 transition-colors">Pricing</a>
			</div>
		  </div>
		</div>
	  </div>
	</nav>
  
	<!-- Main content area -->
	<main class="flex-grow flex-col justify-center items-center">
	  {@render children()}
	</main>
  </div>
{:else}
	{@render children()}
{/if}