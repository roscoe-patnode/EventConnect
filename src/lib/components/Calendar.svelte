<!-- Calendar.svelte -->
<script lang="ts">
    //import { onMount } from 'svelte';
    
    // Define types for calendar day objects
    type CalendarDay = {
        date: Date;
        dayOfMonth: number;
        isCurrentMonth: boolean;
        isToday: boolean;
        isSelected: boolean;
        events: Event[];
    };
    
    // Define type for events
    type Event = {
        id: string;
        name: string;
        dates: string[];
        venue_id: string;
        // Other event properties if needed
    };
  
    // Props to receive events from parent
    const { events = [] } = $props<{ events?: Event[] }>();
  
    // Initialize variables
    let currentDate = $state(new Date());
    let selectedDate = $state(new Date());
    let calendarDays = $state<CalendarDay[]>([]);
    let filteredEvents = $state<Event[]>([]);
    
    // Helper function to get a consistent color for an event
    function getEventColor(eventId: string): string {
        // List of pleasant colors for events
        const colors = [
            '#4a90e2', // blue
            '#50b83c', // green
            '#f49342', // orange
            '#d9534f', // red
            '#9c27b0', // purple
            '#00bcd4', // cyan
            '#ff9800', // amber
            '#8bc34a', // light green
            '#ff5722', // deep orange
            '#607d8b'  // blue grey
        ];
      
        // Use the event ID to deterministically pick a color
        const hashCode = eventId.split('').reduce((acc, char) => {
            return char.charCodeAt(0) + ((acc << 5) - acc);
        }, 0);
      
        return colors[Math.abs(hashCode) % colors.length];
    }
    
    // Generate days for the current month view
    function generateCalendarDays() {
        const year = currentDate.getFullYear();
        const month = currentDate.getMonth();
        
        // First day of the month
        const firstDay = new Date(year, month, 1);
        // Last day of the month
        const lastDay = new Date(year, month + 1, 0);
        
        // Get the day of the week of the first day (0 = Sunday, 1 = Monday, etc.)
        const firstDayOfWeek = firstDay.getDay();
        
        // Calculate days from previous month to show
        const daysFromPrevMonth = firstDayOfWeek;
        
        // Calculate the total days to generate
        // (days in current month + days from prev month + days from next month to complete the grid)
        const totalDaysToShow = 42; // 6 rows of 7 days
        
        // Array to store all calendar days
        const days: CalendarDay[] = [];
        
        // Add days from previous month
        const prevMonth = new Date(year, month, 0);
        const prevMonthDays = prevMonth.getDate();
        
        for (let i = prevMonthDays - daysFromPrevMonth + 1; i <= prevMonthDays; i++) {
            const date = new Date(year, month - 1, i);
            days.push({
            date,
            dayOfMonth: i,
            isCurrentMonth: false,
            isToday: false,
            isSelected: false,
            events: getEventsForDate(date)
            });
        }
        
        // Add days from current month
        const currentMonthDays = lastDay.getDate();
        const today = new Date();
        
        for (let i = 1; i <= currentMonthDays; i++) {
            const date = new Date(year, month, i);
            days.push({
            date,
            dayOfMonth: i,
            isCurrentMonth: true,
            isToday: 
                date.getDate() === today.getDate() && 
                date.getMonth() === today.getMonth() && 
                date.getFullYear() === today.getFullYear(),
            isSelected: 
                date.getDate() === selectedDate.getDate() && 
                date.getMonth() === selectedDate.getMonth() && 
                date.getFullYear() === selectedDate.getFullYear(),
            events: getEventsForDate(date)
            });
        }
        
        // Add days from next month to complete the grid
        const remainingDays = totalDaysToShow - days.length;
        
        for (let i = 1; i <= remainingDays; i++) {
            const date = new Date(year, month + 1, i);
            days.push({
            date,
            dayOfMonth: i,
            isCurrentMonth: false,
            isToday: false,
            isSelected: false,
            events: getEventsForDate(date)
            });
        }
        
        calendarDays = days;
    }
    
    // Format date for header display
    function formatMonthYear(date) {
        return date.toLocaleDateString('en-US', { month: 'long', year: 'numeric' });
    }
    
    // Navigate to previous month
    function prevMonth() {
        currentDate = new Date(currentDate.getFullYear(), currentDate.getMonth() - 1, 1);
        generateCalendarDays();
    }
    
    // Navigate to next month
    function nextMonth() {
        currentDate = new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 1);
        generateCalendarDays();
    }
    
    // Select a date
    function selectDate(day) {
        selectedDate = new Date(day.date);
        // Update isSelected property for all days
        calendarDays = calendarDays.map(d => ({
            ...d,
            isSelected: 
            d.date.getDate() === selectedDate.getDate() && 
            d.date.getMonth() === selectedDate.getMonth() && 
            d.date.getFullYear() === selectedDate.getFullYear()
        }));
        
        // Update filtered events for the selected date
        filteredEvents = getEventsForDate(selectedDate);
    }
    
    // Helper function to get events for a specific date
    function getEventsForDate(date: Date): Event[] {
        if (!events || events.length === 0) return [];
        
        const dateString = date.toISOString().split('T')[0]; // Format: YYYY-MM-DD
        
        return events.filter(event => {
            // Check if this date exists in the event's dates array
            return event.dates && event.dates.includes(dateString);
        });
    }
    
    // Watch for changes in events or currentDate
    $effect(() => {
        if (events) {
            generateCalendarDays();
            // Update filtered events for selected date
            filteredEvents = getEventsForDate(selectedDate);
        }
    });
</script>
  
<div class="calendar-container">
    <div class="calendar-header">
      <button class="nav-button" onclick={prevMonth}>&lt;</button>
      <h2>{formatMonthYear(currentDate)}</h2>
      <button class="nav-button" onclick={nextMonth}>&gt;</button>
    </div>
    
    <div class="weekdays">
      <div class="weekday">Sun</div>
      <div class="weekday">Mon</div>
      <div class="weekday">Tue</div>
      <div class="weekday">Wed</div>
      <div class="weekday">Thu</div>
      <div class="weekday">Fri</div>
      <div class="weekday">Sat</div>
    </div>
    
    <div class="calendar-grid">
        {#each calendarDays as day, i}
                <div 
                class="day-cell {day.isCurrentMonth ? 'current-month' : 'other-month'} 
                        {day.isToday ? 'today' : ''} 
                        {day.isSelected ? 'selected' : ''}"
                onclick={() => selectDate(day)}
                >
                    <span class="day-number">{day.dayOfMonth}</span>
                
                    <!-- Event indicators -->
                    {#if day.events && day.events.length > 0}
                        <div class="event-indicators">
                        {#each day.events.slice(0, 3) as event, i}
                            <div class="event-dot" style="background-color: {getEventColor(event.id)}" title={event.name}></div>
                        {/each}
                        {#if day.events.length > 3}
                            <div class="more-events">+{day.events.length - 3} more</div>
                        {/if}
                        </div>
                    {/if}
                </div>
        {/each}
    </div>

    <!-- Selected date -->
    <div class="selected-date-info">
      <h3>Selected: {selectedDate.toLocaleDateString()}</h3>
      
      <!-- Display events for the selected date -->
      <div class="events-list">
            {#if filteredEvents.length === 0}
                <p class="no-events">No events scheduled for this date.</p>
            {:else}
                {#each filteredEvents as event}
                    <div class="event-item" style="border-left-color: {getEventColor(event.id)}">
                        <span class="event-title">{event.name}</span>
                        <span class="event-dates">
                            {#if event.dates.length === 1}
                                Single day event
                            {:else}
                                Multi-day event ({event.dates.length} days)
                            {/if}
                        </span>
                    </div>
                {/each}
            {/if}
      </div>
    </div>
</div>
  
<style>
.calendar-container {
    font-family: Arial, sans-serif;
    max-width: 800px;
    margin: 0 auto;
    padding: 20px;
    border-radius: 8px;
    box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
    background-color: white;
}

.calendar-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
}

.nav-button {
    background-color: #4a90e2;
    color: white;
    border: none;
    border-radius: 4px;
    padding: 5px 10px;
    cursor: pointer;
    font-size: 16px;
}

.nav-button:hover {
    background-color: #357abD;
}

.weekdays {
    display: grid;
    grid-template-columns: repeat(7, 1fr);
    text-align: center;
    font-weight: bold;
    margin-bottom: 10px;
    background-color: #f8f9fa;
    border-radius: 4px;
}

.weekday {
    padding: 10px;
}

.calendar-grid {
    display: grid;
    grid-template-columns: repeat(7, 1fr);
    grid-template-rows: repeat(6, 1fr);
    gap: 2px;
    background-color: #e9ecef;
    border-radius: 4px;
    overflow: hidden;
}

.day-cell {
    aspect-ratio: 1;
    padding: 5px;
    background-color: white;
    cursor: pointer;
    display: flex;
    flex-direction: column;
    min-height: 80px;
}

.day-cell:hover {
    background-color: #f1f3f5;
}

.day-number {
    margin-bottom: 5px;
    font-weight: 500;
}

.current-month {
    color: #212529;
}

.other-month {
    color: #adb5bd;
}

.today {
    background-color: #e3f2fd;
}

.selected {
    background-color: #bbdefb;
}

.selected-date-info {
    margin-top: 20px;
    padding: 10px;
    border-radius: 4px;
    background-color: #f8f9fa;
}

.event-indicators {
    margin-top: 5px;
    display: flex;
    flex-wrap: wrap;
    gap: 2px;
}

.event-dot {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    background-color: #4a90e2;
    margin-right: 2px;
}

.more-events {
    font-size: 10px;
    color: #6c757d;
    margin-top: 2px;
}

.events-list {
    margin-top: 10px;
}

.no-events {
    color: #6c757d;
    font-style: italic;
}

.event-item {
    padding: 8px;
    margin-bottom: 8px;
    background-color: #e3f2fd;
    border-radius: 4px;
    display: flex;
    flex-direction: column;
    border-left: 4px solid #4a90e2;
}

.event-title {
    margin-top: 4px;
    font-size: 16px;
}
</style>