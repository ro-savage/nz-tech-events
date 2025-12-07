# Design & UI Plan

Visual design guide for making NZ Tech Events look professional and clean.

---

## Design Philosophy

- **Clean & Minimal**: No clutter, focus on content
- **Mobile-First**: Great on phones, scales up nicely
- **Accessible**: Good contrast, readable fonts, keyboard-friendly
- **Fast**: No heavy assets, quick load times
- **Professional but Friendly**: Tech-focused but approachable

---

## Color Palette

### Primary Colors
```css
--primary-600: #2563eb;    /* Blue - buttons, links */
--primary-700: #1d4ed8;    /* Blue - hover states */
--primary-50: #eff6ff;     /* Light blue - backgrounds */
```

### Neutral Colors
```css
--gray-50: #f9fafb;        /* Page background */
--gray-100: #f3f4f6;       /* Card backgrounds */
--gray-200: #e5e7eb;       /* Borders */
--gray-500: #6b7280;       /* Secondary text */
--gray-700: #374151;       /* Body text */
--gray-900: #111827;       /* Headings */
```

### Event Type Colors (Badges)
```css
/* Conference - Purple */
--conference: #7c3aed;
--conference-bg: #f5f3ff;

/* Meetup - Green */
--meetup: #059669;
--meetup-bg: #ecfdf5;

/* Workshop - Orange */
--workshop: #d97706;
--workshop-bg: #fffbeb;

/* Hackathon - Red */
--hackathon: #dc2626;
--hackathon-bg: #fef2f2;

/* Webinar - Teal */
--webinar: #0891b2;
--webinar-bg: #ecfeff;

/* Networking - Pink */
--networking: #db2777;
--networking-bg: #fdf2f8;

/* Other - Gray */
--other: #6b7280;
--other-bg: #f9fafb;
```

---

## Typography

### Font Stack
```css
font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
```

### Scale
```css
/* Headings */
h1: 2.25rem (36px) - Page titles
h2: 1.5rem (24px) - Section titles
h3: 1.25rem (20px) - Card titles

/* Body */
body: 1rem (16px) - Normal text
small: 0.875rem (14px) - Metadata, dates
xs: 0.75rem (12px) - Badges, labels

/* Line height */
headings: 1.2
body: 1.6
```

---

## Layout

### Container
```css
max-width: 800px;  /* Single column, comfortable reading */
padding: 1rem;     /* Mobile */
padding: 2rem;     /* Desktop */
```

### Spacing Scale
```css
--space-1: 0.25rem (4px)
--space-2: 0.5rem (8px)
--space-3: 0.75rem (12px)
--space-4: 1rem (16px)
--space-6: 1.5rem (24px)
--space-8: 2rem (32px)
--space-12: 3rem (48px)
```

---

## Components

### Header
```
┌──────────────────────────────────────────────────┐
│  🗓️ NZ Tech Events              [Post Event] [👤] │
└──────────────────────────────────────────────────┘
```
- Logo/title on left (clickable, returns home)
- "Post Event" button (primary, only when logged in)
- User avatar or "Sign In" on right
- Sticky on scroll (optional)
- White background, subtle bottom border

### Filter Bar
```
┌──────────────────────────────────────────────────┐
│  Region: [All Regions ▼]  City: [All Cities ▼]   │
│  [Clear Filters]                                  │
└──────────────────────────────────────────────────┘
```
- Horizontal on desktop, stacked on mobile
- Clean select dropdowns
- Auto-submit on change (no button needed)
- Clear filters link when filters active

### Event Card
```
┌──────────────────────────────────────────────────┐
│  [Meetup]                            Free        │
│                                                  │
│  Auckland JavaScript Meetup                      │
│  Thursday, 20 March 2025 · 6:00 PM              │
│  📍 Auckland CBD                                 │
│                                                  │
│  Join us for an evening of JavaScript talks     │
│  and networking with the local dev community... │
└──────────────────────────────────────────────────┘
```
- Event type badge (colored, top-left)
- Cost badge (top-right, gray if free, colored if paid)
- Title as link (prominent, blue on hover)
- Date and time (formatted nicely)
- Location with pin icon
- Description excerpt (2-3 lines, truncated)
- Entire card clickable
- Subtle shadow on hover

### Event Detail Page
```
┌──────────────────────────────────────────────────┐
│  ← Back to Events                                │
│                                                  │
│  [Meetup]                                        │
│                                                  │
│  Auckland JavaScript Meetup                      │
│                                                  │
│  📅 Thursday, 20 March 2025                     │
│  ⏰ 6:00 PM - 9:00 PM                           │
│  📍 GridAKL, 12 Madden Street, Auckland CBD     │
│  💰 Free                                        │
│                                                  │
│  [Register →]                                    │
│                                                  │
│  ─────────────────────────────────────────────  │
│                                                  │
│  Full description here with all the details     │
│  about the event. Can be multiple paragraphs.   │
│                                                  │
│  ─────────────────────────────────────────────  │
│                                                  │
│  Posted by Jane Smith                            │
│                                                  │
│  [Edit] [Delete]  ← Only shown to owner         │
└──────────────────────────────────────────────────┘
```

### Event Form
```
┌──────────────────────────────────────────────────┐
│  Create New Event                                │
│                                                  │
│  Title *                                         │
│  ┌────────────────────────────────────────────┐ │
│  │ Auckland JavaScript Meetup                  │ │
│  └────────────────────────────────────────────┘ │
│                                                  │
│  Event Type *                                    │
│  ┌────────────────────────────────────────────┐ │
│  │ Meetup                               ▼     │ │
│  └────────────────────────────────────────────┘ │
│                                                  │
│  ┌─────────────────┐  ┌─────────────────┐       │
│  │ Start Date *    │  │ End Date        │       │
│  │ 20/03/2025      │  │                 │       │
│  └─────────────────┘  └─────────────────┘       │
│                                                  │
│  ┌─────────────────┐  ┌─────────────────┐       │
│  │ Start Time      │  │ End Time        │       │
│  │ 18:00           │  │ 21:00           │       │
│  └─────────────────┘  └─────────────────┘       │
│                                                  │
│  Region *                City *                  │
│  ┌──────────────┐       ┌──────────────┐        │
│  │ Auckland ▼   │       │ Auckland CBD▼│        │
│  └──────────────┘       └──────────────┘        │
│                                                  │
│  Address                                         │
│  ┌────────────────────────────────────────────┐ │
│  │ GridAKL, 12 Madden Street                  │ │
│  └────────────────────────────────────────────┘ │
│                                                  │
│  Cost                                            │
│  ┌────────────────────────────────────────────┐ │
│  │ Free                                       │ │
│  └────────────────────────────────────────────┘ │
│                                                  │
│  Registration Link                               │
│  ┌────────────────────────────────────────────┐ │
│  │ https://meetup.com/auckland-js            │ │
│  └────────────────────────────────────────────┘ │
│                                                  │
│  Description *                                   │
│  ┌────────────────────────────────────────────┐ │
│  │                                            │ │
│  │                                            │ │
│  │                                            │ │
│  └────────────────────────────────────────────┘ │
│                                                  │
│  [Cancel]                    [Create Event]     │
└──────────────────────────────────────────────────┘
```

### Empty States
```
┌──────────────────────────────────────────────────┐
│                                                  │
│              📅                                  │
│                                                  │
│        No upcoming events                        │
│        Check back soon or post your own!         │
│                                                  │
│            [Post an Event]                       │
│                                                  │
└──────────────────────────────────────────────────┘
```

---

## Responsive Breakpoints

```css
/* Mobile first */
default: 0 - 639px    (single column, stacked)
sm: 640px+            (minor adjustments)
md: 768px+            (side-by-side form fields)
lg: 1024px+           (max container width)
```

---

## Tailwind Classes Reference

### Common Patterns

**Card**
```html
<article class="bg-white rounded-lg border border-gray-200 p-6 hover:shadow-md transition-shadow">
```

**Primary Button**
```html
<button class="bg-blue-600 hover:bg-blue-700 text-white font-medium px-4 py-2 rounded-md transition-colors">
```

**Secondary Button**
```html
<button class="bg-white hover:bg-gray-50 text-gray-700 font-medium px-4 py-2 rounded-md border border-gray-300 transition-colors">
```

**Danger Button**
```html
<button class="bg-red-600 hover:bg-red-700 text-white font-medium px-4 py-2 rounded-md transition-colors">
```

**Badge**
```html
<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
```

**Form Input**
```html
<input class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500">
```

**Form Label**
```html
<label class="block text-sm font-medium text-gray-700 mb-1">
```

---

## Iconography

Use simple emoji or a lightweight icon set (Heroicons inline SVGs):

- 📅 Calendar/Date
- ⏰ Time
- 📍 Location
- 💰 Cost
- 🔗 External link
- ← Back arrow
- ▼ Dropdown arrow

---

## Interaction States

### Links
```
default: text-blue-600
hover: text-blue-800, underline
focus: ring-2 ring-blue-500
```

### Buttons
```
default: bg-blue-600
hover: bg-blue-700
active: bg-blue-800
focus: ring-2 ring-blue-500 ring-offset-2
disabled: bg-gray-300, cursor-not-allowed
```

### Cards
```
default: border-gray-200
hover: shadow-md, slight lift
```

### Form Inputs
```
default: border-gray-300
focus: border-blue-500, ring-2 ring-blue-500
error: border-red-500, ring-red-500
```

---

## Animation

Keep animations subtle and purposeful:

```css
/* Standard transition */
transition: all 150ms ease-in-out;

/* Card hover lift */
transform: translateY(-2px);

/* Button press */
transform: scale(0.98);
```

---

## Accessibility Checklist

- [ ] Color contrast meets WCAG AA (4.5:1 for text)
- [ ] All interactive elements are keyboard accessible
- [ ] Focus states are visible
- [ ] Form labels are associated with inputs
- [ ] Error messages are descriptive
- [ ] Skip to main content link
- [ ] Alt text for any images
- [ ] Semantic HTML elements
