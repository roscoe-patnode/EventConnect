<script lang="ts">
    import { supabase } from '$lib/supabaseClient';
    import { goto } from '$app/navigation';

    let pageState = $state("LogIn")
    let loading = false;
    let firstName = '';
    let lastName = '';
    let email = $state('');
    let password = '';
    let accountType = 'personal'; // Default supabase value
    let errorMessage = $state('');
    let rememberMe = $state(false);
    let resendMessage = $state('');
    let signupSubmitted = $state(false);
    
    async function handleSignup() {
        try {
            loading = true;
            errorMessage = '';
            
            // 1. Register user with Supabase Auth
            const { data: authData, error: authError } = await supabase.auth.signUp({
            email,
            password,
            options: {
                data: {
                first_name: firstName,
                last_name: lastName,
                role: accountType // Store role in user metadata
                }
            }
            });
        
            if (authError) throw authError;
        
            // 2. Insert additional user data into a custom 'profiles' table
            if (authData.user) {
                const { error: profileError } = await supabase
                    .from('profiles')
                    .insert([
                    { 
                        id: authData.user.id,
                        first_name: firstName,
                        last_name: lastName,
                        email: email,
                        role: accountType
                    }
                ]);
                
                if (profileError) throw profileError;
        
                // Set flag to show verification banner
                signupSubmitted = true;
                // Don't redirect yet - only show verification banner
                
            }
        } catch (error:any) {
            errorMessage = error.message || 'An error occurred during sign up';
            console.error('Error:', error);
        } finally {
            loading = false;
        }
    }

    async function handleSignIn() {
        try {
            loading = true;
            errorMessage = '';
            
            // Supabase sign in
            const { data, error } = await supabase.auth.signInWithPassword({
                email,
                password,
                options: {
                    // Set session duration based on rememberMe
                    // 30 days if remember me is checked, 1 hour if not
                    // @ts-ignore
                    expiresIn: rememberMe ? 60 * 60 * 24 * 30 : 60 * 60
                }
            });
    
            if (error) throw error;

            // Check if email is verified
            if (!data.user?.email_confirmed_at) {
                errorMessage = 'Please verify your email before signing in. Check your inbox for the verification link.';
                return;
            }

            // If remember me is checked, store the session
            if (rememberMe) {
                const { error: sessionError } = await supabase.auth.setSession({
                    access_token: data.session.access_token,
                    refresh_token: data.session.refresh_token
                });
            
                if (sessionError) throw sessionError;
            }
    
            // Fetch user profile to get role
            const { data: profileData, error: profileError } = await supabase
                .from('profiles')
                .select('role')
                .eq('id', data.user.id)
                .single();
    
            if (profileError) throw profileError;
    
            // Redirect based on role
            const role = profileData.role;
            if (role === 'event_planner') {
                goto('/dashboard/planner');
            } else if (role === 'facility_owner') {
                goto('/dashboard/facility_owner');
            } else if (role === 'staff_member') {
                goto('/dashboard/staff');
            } else {
            goto('/dashboard');
            }
    
        } catch (error: any) {
            errorMessage = error.message || 'Failed to sign in';
            console.error('Error:', error);
        } finally {
            loading = false;
        }
    }

    // resend email
    async function handleResend() {
        try {
            const { error } = await supabase.auth.resend({ 
                type: 'signup', 
                email 
            });
            if (error) throw error;
                resendMessage = 'Verification email sent! Please check your inbox.';
        } catch (error) {
            resendMessage = 'Failed to send verification email. Please try again.';
        }
    }

</script>

{#if pageState === "SignUp"}
  
    <div class="max-w-5xl mx-auto bg-white p-8 rounded-lg shadow-md my-8">
        <div class="mb-6">
            <h2 class="text-2xl font-semibold text-gray-800 mb-2">Create Account</h2>
            <p class="text-gray-600">Join us today to access exclusive features</p>
        </div>
        
        {#if errorMessage}
            <div class="bg-red-50 border-l-4 border-red-500 p-4 mb-6">
                <p class="text-red-700">{errorMessage}</p>
            </div>
        {/if}

        <!-- Verification Banner - shows after successful signup -->
        {#if signupSubmitted}
            <div class="bg-blue-50 border-l-4 border-blue-500 p-4 mb-6">
                <p class="text-blue-700">Please verify your email before signing in. Check your inbox for the verification link.</p>
                <button 
                    class="text-indigo-600 hover:underline mt-2 text-sm"
                    onclick={handleResend}
                >
                    Resend verification email
                </button>
                {#if resendMessage.length > 0}
                    <p class="text-sm text-green-600 mt-1">{resendMessage}</p>
                {/if}
                
                <div class="mt-4">
                    <button 
                        onclick={() => pageState = "LogIn"}
                        class="text-sm bg-indigo-600 text-white py-1 px-3 rounded-md hover:bg-indigo-700 transition-colors"
                    >
                        Go to Login
                    </button>
                </div>
            </div>
        {/if}
        
        <!-- Account Type Selection -->
        <div class="mb-6">
        <label class="block text-gray-700 font-medium mb-3">Account Type</label>
            <div class="flex space-x-6">
                <label class="flex items-center">
                <input type="radio" bind:group={accountType} name="accountType" value="event_planner" class="h-5 w-5 text-indigo-600" checked>
                <span class="ml-2 text-gray-700">Event Planner</span>
                </label>
                <label class="flex items-center">
                <input type="radio" bind:group={accountType} name="accountType" value="facility_owner" class="h-5 w-5 text-indigo-600">
                <span class="ml-2 text-gray-700">Facility Owner</span>
                </label>
                <label class="flex items-center">
                <input type="radio" bind:group={accountType} name="accountType" value="staff_member" class="h-5 w-5 text-indigo-600">
                <span class="ml-2 text-gray-700">Staff member</span>
                </label>
            </div>
        </div>
        
        <form class="space-y-6" onsubmit={handleSignup}>
        <!-- Name fields - side by side -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
            <label for="firstName" class="block text-gray-700 font-medium mb-2">First Name</label>
            <input 
                type="text" 
                id="firstName"
                bind:value={firstName}
                class="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
                placeholder="Enter your first name"
                required
            >
            </div>
            <div>
            <label for="lastName" class="block text-gray-700 font-medium mb-2">Last Name</label>
            <input 
                type="text" 
                id="lastName" 
                bind:value={lastName}
                class="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
                placeholder="Enter your last name"
                required
            >
            </div>
        </div>
        
        <!-- Email -->
        <div>
            <label for="email" class="block text-gray-700 font-medium mb-2">Email Address</label>
            <input 
            type="email" 
            id="email" 
            bind:value={email}
            class="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
            placeholder="you@example.com"
            required
            >
        </div>
        
        <!-- Password -->
        <div>
            <label for="password" class="block text-gray-700 font-medium mb-2">Password</label>
            <input 
            type="password" 
            id="password" 
            bind:value={password}
            class="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
            placeholder="Create a secure password"
            required
            >
            <p class="mt-1 text-sm text-gray-500">Must be at least 8 characters</p>
        </div>
        
        <!-- Terms and conditions -->
        <div class="flex items-start">
            <input 
            type="checkbox" 
            id="terms" 
            class="mt-1 h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
            required
            >
            <label for="terms" class="ml-2 block text-sm text-gray-700">
            I agree to the <a href="#" class="text-indigo-600 hover:underline">Terms of Service</a> and <a href="#" class="text-indigo-600 hover:underline">Privacy Policy</a>
            </label>
        </div>
        
        <!-- Submit button -->
        <div>
            <button
            type="submit" 
            class="w-full bg-indigo-600 text-white py-3 px-4 rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 transition-colors"
            >
            {loading ? 'Creating Account...' : 'Create Account'}
            </button>
            <!-- onclick= {handleSignup} -->
        </div>
        
        <!-- Sign in link -->
        <div class="text-center">
            <p class="text-gray-600">
            Already have an account? 
            <button onclick={() => pageState = "LogIn"} class="text-indigo-600 font-medium hover:underline">Sign in</button>
            </p>
        </div>
        </form>
    </div>

{:else if pageState === "LogIn"}

    <div class="max-w-5xl mx-auto bg-white p-8 rounded-lg shadow-md my-8">
        <div class="mb-6">
        <h2 class="text-2xl font-semibold text-gray-800 mb-2">Welcome Back</h2>
        <p class="text-gray-600">Log in to access your account</p>
        </div>
        
        {#if errorMessage.length > 0}
            <div class="bg-red-50 border-l-4 border-red-500 p-4 mb-6">
                <p class="text-red-700">{errorMessage}</p>
                <button 
                    class="text-indigo-600 hover:underline mt-2 text-sm"
                    onclick={handleResend}
                >
                    Resend verification email
                </button>
                {#if resendMessage.length > 0}
                    <p class="text-sm text-green-600 mt-1">{resendMessage}</p>
                {/if}
            </div>
        {/if}

        <form class="space-y-6" onsubmit={handleSignIn}>
        <!-- Email -->
        <div>
            <label for="email" class="block text-gray-700 font-medium mb-2">Email Address</label>
            <input 
            type="email" 
            id="email" 
            bind:value={email}
            class="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
            placeholder="you@example.com"
            required
            >
        </div>
        
        <!-- Password -->
        <div>
            <label for="password" class="block text-gray-700 font-medium mb-2">Password</label>
            <input 
            type="password" 
            id="password" 
            bind:value={password}
            class="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
            placeholder="Enter your password"
            required
            >
            <div class="flex justify-end mt-1">
            <a href="#" class="text-sm text-indigo-600 hover:underline">Forgot password?</a>
            </div>
        </div>
        
        <!-- Remember me -->
        <div class="flex items-center justify-between">
            <div class="flex items-center">
            <input 
                type="checkbox" 
                id="remember" 
                bind:checked={rememberMe}
                class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
            >
            <label for="remember" class="ml-2 block text-sm text-gray-700">
                Remember me
            </label>
            </div>
        </div>
        
        <!-- Login button -->
        <div>
            <button 
            type="submit" 
            class="w-full bg-indigo-600 text-white py-3 px-4 rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 transition-colors"
            >
            {loading ? 'Signing in...' : 'Log In'}
            </button>
        </div>
        
        <!-- Sign up link -->
        <div class="text-center">
            <p class="text-gray-600">
            Don't have an account? 
            <button onclick={() => pageState = "SignUp"} class="text-indigo-600 font-medium hover:underline">Sign up</button>
            </p>
        </div>
        </form>
    </div>
{/if}
