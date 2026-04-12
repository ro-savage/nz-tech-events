require 'csv'

# Descriptions keyed by [title, start_date] for specific events
# and by title alone for recurring events (used as fallback)

TITLE_DESCRIPTIONS = {
  "DINZ Virtual Coffee Chat" => <<~MD.strip,
    An informal monthly drop-in coffee chat hosted by Digital Identity NZ (DINZ), open to anyone in the digital identity community across Aotearoa. Each 45-minute session provides space for discussion, ideas exchange, and connection with others working in or interested in digital identity.

    Register once for the series and join whichever sessions suit your schedule. It's a relaxed, low-commitment way to stay connected with the DINZ community and keep up with what's happening in the digital identity space in New Zealand.
  MD

  "Kapiti Startup & Innovation Network" => <<~MD.strip,
    A fortnightly morning coffee catch-up for Kāpiti Coast innovators, entrepreneurs, and startup enthusiasts. The group brings together people who love sharing startup stories — the good, the bad, and the ugly — and believes in the magic that happens when energised people get in a room together to exchange ideas.

    Join from around 8:00 AM at 180 Degrees Cafe & Bistro, Paraparaumu Beach, for an informal session of business support, inspiration, and local networking. Everyone is welcome, whether you're just starting out or well into your entrepreneurial journey.
  MD

  "Auckland Makes Games" => <<~MD.strip,
    A social and co-working hangout run by Auckland Makes Games, a community organisation dedicated to supporting Auckland's game development scene. Whether you're a developer, artist, or simply interested in game creation, this is a space to connect, collaborate, and help each other out.

    The group runs regular events including daytime co-working sessions at GridAKL/John Lysaght Building and social evenings at local venues. It's a welcoming community for anyone interested in connecting with Auckland's game dev scene.
  MD

  "Cryptocurrency NZ Meetup" => <<~MD.strip,
    Monthly in-person grassroots community meetups held on the last Wednesday of every month across 12 locations throughout Aotearoa New Zealand. From Auckland and Wellington to Christchurch, Dunedin, and Queenstown, Kiwis come together to discuss all things Bitcoin, Ethereum, cryptocurrencies, financial liberty, NFTs, DAOs, and beyond.

    Whether you're a seasoned crypto enthusiast or just curious about digital assets, these meetups are open to everyone. It's a chance to connect with your local crypto community and stay across what's happening in the space. Check the Cryptocurrency NZ website for your nearest location.
  MD

  "Agritech Unleashed" => <<~MD.strip,
    Agritech Unleashed is a series of regionally distributed experiences celebrating and exploring the unique characteristics of each region's agritech ecosystem. Every region across Aotearoa has distinct agricultural priorities, challenges, stakeholders, and infrastructure that influence how agritech innovations are adopted and scaled.

    These events create a platform for meaningful conversations that highlight unique regional strengths in agritech, bringing together farmers, technologists, researchers, and industry leaders. Organised by AgriTech New Zealand, each event is tailored to its host region's specific agricultural landscape.
  MD
}

SPECIFIC_DESCRIPTIONS = {
  ["FLINT Auckland - Startups VS Corporates - Shaping Your Career", "2026-04-08"] => <<~MD.strip,
    A panel event exploring the key differences between working in startups and corporates in technology roles, designed to help you shape your career path. Three experienced tech leaders — Peter Hwang (Co-Founder & Head of AI, Sevaka), Steph Randell (Senior AI and Data Product Manager, One NZ), and Shanon Jackson (Principal Engineer, Atlassian) — share their experiences across both environments.

    The evening covers workplace myths, which personality types thrive in different settings, and strategies for maximising career growth. Doors open at 5:30 PM with the panel starting at 6:00 PM, followed by networking from 7:00 PM. Hosted by FLINT and TUANZ at One New Zealand, Freemans Bay, Auckland.
  MD

  ["Nelson - Empower Her Networking - The Story Behind the Brand", "2026-04-10"] => <<~MD.strip,
    Empower Her is a female networking group offering a welcoming and safe environment for women of all business backgrounds and experiences. This session, "The Story Behind the Brand," brings together women in the Nelson region to share their stories, build connections, and support each other's business journeys.

    Join at Moutere Hills Restaurant and Cellar Door for a morning of networking, inspiration, and authentic conversation.
  MD

  ["GEN NZ Motu Connect", "2026-04-14"] => <<~MD.strip,
    A monthly online gathering hosted by the Global Entrepreneurship Network New Zealand (GEN NZ). Each session features a keynote speaker, impromptu introductions between community members, and an "asks and offers" segment where participants can help each other work through local challenges.

    It's a chance to connect with others across the New Zealand entrepreneurship ecosystem, share knowledge, and build meaningful relationships — all from the comfort of your own screen.
  MD

  ["Women and Non-Binary Folk STEM TRG - The Leadership Series", "2026-04-14"] => <<~MD.strip,
    Part of an engaging leadership workshop series inspired by Brené Brown's *Dare to Lead*, exploring four pillars of courageous leadership: rumbling with vulnerability, living into our values, braving trust, and learning to rise. This session continues exploring vulnerability and begins unpacking the role of empathy in courageous leadership.

    Hosted by Women in STEM TGA, whose mission is creating an inclusive and safe community for women and non-binary people working in, studying, or interested in STEM in the Tauranga area. Doors open at 5:00 PM at Basestation, 148 Durham Street, Tauranga. Light refreshments provided and free CBD parking is available after 5:00 PM.
  MD

  ["KiwiSaaS | GTM Engineering: automate, scale, win", "2026-04-15"] => <<~MD.strip,
    GTM (Go-To-Market) Engineering is reshaping how the world's fastest-growing companies go to market. Companies like Canva, Stripe, Ramp, and OpenAI are already doing it — generating substantial pipeline growth without scaling headcount to match. In Aotearoa, this approach is barely on the radar, yet the opportunity for local SaaS companies is real.

    Join Wedge GTM founder Paul Zaruchevsky, Re-Leased's Director of Growth Dulan Perera, and Tracksuit's Senior GTM Operations Manager Nick Rust for an exclusive in-person workshop covering what GTM Engineering is, why it's gaining traction, the essential tools, required skills, and real-world implementation examples. Ideal for marketing, sales, and revenue operations leaders responsible for driving growth.
  MD

  ["\u{1F525} Job Hackers Mixer \u{2014} Live Q&A, Real Stories & Breakout Connections", "2026-04-15"] => <<~MD.strip,
    A high-energy online meetup designed to give real answers, real inspiration, and real connections for anyone actively job hunting, navigating a career pivot, or wanting to stay sharp in today's job market.

    The evening features a Hot Seat Q&A with recruiters and hiring insiders answering your burning questions about what they actually look for and what kills a candidate's chances. You'll also hear real wins and strategies from fellow job seekers in the Community Spotlight, then jump into Breakout Rooms for small group connections with potential collaborators and accountability partners.
  MD

  ["Fintech Festival", "2026-04-16"] => <<~MD.strip,
    Come celebrate the founders graduating from Fintech Lab 2026 at this gathering of the Kiwi startup community. Fintech is the fastest-growing tech sector in New Zealand, and these startups are creating jobs, enabling more Kiwis to build wealth, driving healthy competition in the finance industry, and generating valuable intellectual property for Aotearoa.

    Sponsored by Mastercard and supported by organisations including the Financial Markets Authority, WellingtonNZ, and MBIE, the Fintech Festival is a day to celebrate startups, Kiwi innovation, and the people investing in the future of New Zealand. Join at Shed 6, Wellington, for an afternoon and evening of pitches, networking, and inspiration.
  MD

  ["EdTechNZ Community Connect Event \u{2013} Auckland", "2026-04-16"] => <<~MD.strip,
    Connect in-person with the New Zealand EdTech community in Auckland! Hosted by EdTech New Zealand Executive Director Dean Watson, this is a free, informal event designed to bring together anyone interested in education technology — whether you're an EdTechNZ member or not.

    Join at Sweat Shop Brew Kitchen, 7 Sale Street, Freemans Bay, for an evening of networking and conversation that could open new doors in the EdTech space. Please register so the organisers can get an idea of numbers.
  MD

  ["EdTechNZ Community Connect Event \u{2013} Wellington", "2026-04-16"] => <<~MD.strip,
    Connect in-person with the New Zealand EdTech community in Wellington! Hosted by EdTech New Zealand, this is a free, informal event designed to bring together anyone interested in education technology — whether you're an EdTechNZ member or not.

    Join at Cuba St Tavern, Wellington, for an evening of networking and conversation with others passionate about the intersection of education and technology in Aotearoa.
  MD

  ["EdTechNZ Community Connect Event \u{2013} Christchurch", "2026-04-16"] => <<~MD.strip,
    Connect in-person with the New Zealand EdTech community in Christchurch! Hosted by EdTech New Zealand, this is a free, informal event designed to bring together anyone interested in education technology — whether you're an EdTechNZ member or not.

    Join at Winnie Bagoes Ferrymead, Christchurch, for an evening of networking and conversation with others passionate about the intersection of education and technology in Aotearoa.
  MD

  ["Prompt Like a Pro: Practical AI Techniques", "2026-04-17"] => <<~MD.strip,
    A high-energy, hands-on workshop where you'll practice live with ChatGPT, Gemini, Claude, and Perplexity while learning the PILLARS framework for reliably great prompts. You'll distil long PDFs in minutes, create a Custom GPT that mirrors your voice, compare models side-by-side, and use Advanced Voice Mode to rehearse tough conversations.

    Whether you're new to AI tools or looking to level up your prompting skills, this online workshop offers practical techniques you can apply immediately in your work and daily life.
  MD

  ["AI Forum Webinar Series: Real AI Case Studies and Success Stories from the Field", "2026-04-17"] => <<~MD.strip,
    Part of a seven-part collaborative webinar series hosted by AI Forum NZ in partnership with ACE New Zealand and presented by academyEX. This session, "Blueprint 2046," explores what architecture, engineering, and construction could look like two decades from now in the age of AI.

    Panellists from across the AEC sector discuss topics including AI-driven infrastructure that self-heals to climate change, Māori data sovereignty when buildings become part of a living data ecosystem, and avoiding "algorithmic slums" optimised for cost but devoid of culture. A thought-provoking 90-minute online session with practical takeaways for anyone working at the intersection of AI and the built environment.
  MD

  ["EdTechNZ Community Connect Event", "2026-04-18"] => <<~MD.strip,
    Connect in-person — and on a family farm — with the New Zealand EdTech community for the first time in Hamilton! Hosted by EdTechNZ board member Adam Walmsley and Executive Director Dean Watson, this is a free, informal event open to both EdTechNZ members and non-members.

    A unique opportunity to network with others passionate about education technology in a relaxed rural setting near Hamilton CBD. The address will be provided 48 hours before the event. Register so the organisers can plan accordingly.
  MD

  ["Governance for Growth", "2026-04-20"] => <<~MD.strip,
    Governance is critically important for early-stage companies, and the popularity of these workshops reflects how much founders and their investors recognise this. Angel Association New Zealand, Callaghan Innovation, and CreativeHQ invite you to join this Governance for Growth workshop in Wellington.

    During the session, governance experts Debra Hall and Greg Sitters, along with a local directors' fireside chat, will take you through the intricacies of governance for startups and growth-stage companies. Held at Creative HQ, Level 1, 7 Dixon Street, Wellington.
  MD

  ["Movac Sales Jam", "2026-04-21"] => <<~MD.strip,
    Six growth leaders tell their best and worst stories of selling Kiwi technology to the world's most discerning buyers. This structured but informal and rapid-fire event features Danny Purcell (Basis), Luke Campbell (VXT), Laurissa Hollis (ex-Blackpearl Group), Padraig Bakker (Kindo), Charlie Marsh (Tradify), and Adam Clark (M-Com/Groov/Maximus/Tutaki), hosted by Serge van Dam, Movac Operating Partner.

    The afternoon includes plenty of time to ask questions, mingle with peers, and hatch global domination plans. The Movac Sales Jam is exclusively for sales professionals, growth leaders, and founders in New Zealand-headquartered tech companies. Jamming runs 2:00–5:00 PM followed by networking drinks and nibbles until 6:30 PM at the Royal New Zealand Yacht Squadron, Westhaven Marina.
  MD

  ["AI Engineering TRG | 0.1 Setup", "2026-04-21"] => <<~MD.strip,
    The inaugural gathering of the Hype Cycle Club — a new community for software engineers, product builders, indie hackers, and curious tinkerers in Tauranga who want to actually build with AI and figure out what works. In a world saturated with AI hype, new tools, and big claims, this group cuts through the noise.

    Expect open discussion about what's genuinely useful versus overhyped, hands-on exploration of tools and workflows, optional lightning demos, and networking. Unfinished and half-baked ideas are encouraged. The vibe is casual, interactive, and builder-focused. All experience levels welcome.
  MD

  ["Careers of the Future: Global Opportunities", "2026-04-21"] => <<~MD.strip,
    New Zealand startups are going global from day one, creating unique opportunities for people at every stage of their careers. Whether you're exploring your first role in a startup or already part of one, working in a Kiwi startup can open doors to global experiences, new markets, and opportunities to live and work overseas.

    Join Icehouse Ventures and Humankind for an evening exploring how Kiwi startups operate with a global mindset. Hear from Michaela Egbers (Ideally), Emily Hett (Halter), Tim Judd (Timescapes), and Christine van Hoffen (Concord) about how they've navigated international pathways and built global connections. Drinks and nibbles provided at Icehouse Ventures, Parnell.
  MD

  ["Cleantech Expo - Auckland", "2026-04-22"] => <<~MD.strip,
    The first national Cleantech Expo brings together over 30 New Zealand cleantech innovation businesses to showcase breakthrough solutions in circular economy, energy, waste-to-value, low-emissions alternatives, and more. A future-focused community of innovators is gathering in Tāmaki Makaurau Auckland to demonstrate practical, scalable cleantech opportunities.

    The expo features company showcases, a lunchtime pitch session for government procurement teams and industry partners, networking with cleantech founders, and career exploration opportunities for STEM students. Participating companies include Bactosure, Mushroom Material, UsedFULLY, Aspiring Materials, and many more. Organised by Auckland Council's Economic Development Office and hosted at AUT.
  MD

  ["Ministry of Awesome: Coffee & Jam - #370", "2026-04-23"] => <<~MD.strip,
    Christchurch's longest-running founder meetup, Coffee & Jam brings together the startup community for lunchtime connection, learning, and collaboration. Whether you're an early-stage entrepreneur or an experienced founder, this is a welcoming space to hear real stories and build meaningful connections.

    This edition features speakers Sam Webber (Halo Internet), Diego Ramirez (hmn.plus), Lucy Law (NZGCP), and Dr Lari Dkhar (NZGCP). Light refreshments provided. Held at EPIC Christchurch, 100 Manchester Street, in collaboration with Dentons.
  MD

  ["Think aloud! 30-min chat for people doing product research", "2026-04-27"] => <<~MD.strip,
    A 30-minute online conversation for anyone doing product research in New Zealand — UX researchers, product managers, service designers, or anyone working directly with users. The format is designed to fit into a busy schedule: 2 minutes of intro, 5 minutes of speed-dating 1:1 chats, 20 minutes of small group discussion on a voted topic, and 3 minutes to wrap up.

    Attendees submit topics beforehand and the group votes to select the discussion subject. It's a relaxed, honest space to swap ideas and talk about the messy, real parts of research work. All experience levels welcome. Runs every second month.
  MD

  ["VenturEd Live", "2026-04-29"] => <<~MD.strip,
    A two-day professional development programme for investors who want to keep sharpening the craft of investing. Day one is live and in-person at the Aotea Centre in Auckland; day two is a bonus virtual session. The programme covers high-stakes conversations, decision-making and bias, AI in investment decisions, and strategic relationships.

    Speakers include Stu Van Rij (High-Stakes Conversation Strategist), Prof. Jill Klein (Melbourne Business School), David Beard (Movac), Randy Komisar (ex-Kleiner Perkins), and James Pinner (NZGCP). Capped at 60 attendees and subsidised by NZGCP, this is an intimate and high-value experience for anyone working across the venture and investment ecosystem.
  MD

  ["Aurora Climate Lab Launch night", "2026-04-29"] => <<~MD.strip,
    Meet the founders in the 2026 cohort of the Aurora Climate Lab — Aotearoa's leading Climate Tech Accelerator run by Creative HQ. This launch night is your chance to meet 15 innovative ventures tackling the planet's biggest challenges, including Aspiring Materials, Solarferm, CarbonClick, Hikotron, LandAI, and more.

    Join for an inspiring evening to show these founders how much our community has their back and be part of the movement making New Zealand a world leader in climate innovation. Drinks, networking, and the chance to connect with the next wave of climate tech innovators. Capped at 130 attendees at Creative HQ, Wellington.
  MD

  ["Network on Your Terms with Powrsuit &  W\u{0101}hine Fuelled Tech", "2026-04-30"] => <<~MD.strip,
    A networking event co-hosted by Powrsuit and Wāhine Fuelled Tech, bringing together their shared focus on practical, inclusive networking for women in tech and business. The evening features drinks, food, and opportunities to build meaningful, authentic connections in a relaxed social setting.

    Join at Creative HQ, Level 1, 7 Dixon Street, Wellington, for an evening designed to help you connect on your own terms.
  MD

  ["VESA Hackathon 2026", "2026-05-01"] => <<~MD.strip,
    An inclusive three-day hackathon inviting students of all skill levels to prototype software, gain mentorship, and build portfolio-ready projects. Whether you're a beginner or experienced coder, this is a chance to collaborate with fellow students, learn new skills, and create something you can be proud of.

    Organised by VESA, VEC, and VUWWIT at The Atom/Foyer, Pipitea Campus, Wellington. Running from 1–3 May 2026.
  MD

  ["AI and Creativity Summit", "2026-05-05"] => <<~MD.strip,
    Now in its third year, the AI and Creativity Summit explores how AI is reshaping creative industries in Aotearoa and across the world. The event brings global conversations into a local context, creating space for nuance and practical insight — from storytelling in a technology-driven world to misinformation and creative rights.

    The Auckland session takes place at Te Puna Creative Hub, Henderson. Whether you work in design, music, film, writing, or any creative field, this summit is designed to spark meaningful conversations about what comes next when AI meets creativity.
  MD

  ["Soda Power Lunch with AJ Tills", "2026-05-05"] => <<~MD.strip,
    Join Soda for a lunchtime session with AJ Tills, a global marketing leader with 15 years' experience at high-growth technology companies around the world. AJ was Uber's first hire in New Zealand before becoming Head of Marketing for Australia and NZ, followed by global roles at major tech and education companies. He recently took up the role of Chief Customer Officer and US President for Exaba, a tech startup that has raised $8 million in seed funding.

    Hear AJ's story of helping grow global tech companies from the ground up, followed by a Q&A session. Lunch and networking from 12:00 PM, Q&A from 12:45 PM at Gallagher Hub, Wintec, Hamilton.
  MD

  ["AI and Creativity Summit", "2026-05-06"] => <<~MD.strip,
    The AI and Creativity Summit brings global perspectives on AI and creativity into an Aotearoa context. The goal is not to rush to answers, but to prompt curious minds to explore what is changing and what matters most. Across two cities, the summit examines real creative practice, new opportunities, and the tensions that come with speed — including truth and trust, copyright and attribution, social licence, and the future of creative craft.

    The Wellington session takes place at Datacom, 55 Featherston Street, Pipitea. Curiosity is the starting point. Responsibility is the standard.
  MD

  ["PowerUp Accelerator Showcase Night 2026", "2026-05-13"] => <<~MD.strip,
    Five promising startups take the stage at the PowerUp Accelerator Showcase, delivered by Te Puna Umanga Venture Taranaki. After a 10-week intensive programme of tailored mentoring and expert support, these founders are ready to pitch their visions: Flytte (online logistics marketplace), Rooted Harmony (wellness drink blends), Green Loop (commercial food waste to compost), Kermit Shade & Shelter (modular shade systems), and TipJar (digital payments).

    Guest speaker Iain Hosie, Taranaki-born deep-tech entrepreneur and founder of Nanolayr, shares his journey. Hosted by David Downs, CEO of the New Zealand Story Group. Light refreshments provided. Available in person at The Devon Hotel, New Plymouth, or online via livestream.
  MD

  ["AI Forum Webinar Series: Governance, Risk & Compliance", "2026-05-15"] => <<~MD.strip,
    Part of a seven-part collaborative webinar series hosted by AI Forum NZ in partnership with ACE New Zealand and presented by academyEX. As AI moves from pilots to day-to-day delivery in architecture, engineering, and construction, the risk profile changes significantly.

    This session translates legal, ethical, and contractual obligations into practical guardrails you can implement now, covering IP ownership and AI-generated content, contract clauses for AI use in projects, quality assurance and liability considerations, and developing organisation-wide AI policies. Designed for executives, legal counsel, risk and compliance teams, and practice leads. Recording and slides shared with all registrants.
  MD

  ["Marketers Day Auckland", "2026-05-22"] => <<~MD.strip,
    A one-day, festival-style experience designed to be fun and educational for marketers at every stage of their career — from students and fresh graduates to fractional CMOs. The day features four panel discussions with speakers sharing practical tips, what works and what doesn't, and ideas you can take straight into your own work.

    Speakers include James Hurman (Previously Unavailable), Jess Bovey (NZ Police), Cynatra Major (BLUNT Umbrellas), Carsten Grueber (ex-Google/Meta/TikTok), and more. Held at The Garden, 44 George Street, Mt Eden, Auckland. Organised by The Marketing Club AU/NZ.
  MD

  ["Seeds Impact Conference 2026", "2026-05-22"] => <<~MD.strip,
    The third Seeds Impact Conference, presented by Parry Field Lawyers, is a half day of online panel discussions celebrating positive change and new models for the future. Featuring many former Seeds podcast guests and friends, the aim is to focus on impact and initiatives showing meaningful change across housing, education, entrepreneurship, and more.

    Sessions include discussions on the economy with Shamubeel Eaqub (Simplicity), housing innovation, startup ecosystems with Graham Scown (Ministry of Awesome) and Martin Cudd (ChristchurchNZ), and changing paradigms across climate, social enterprise, and community development. Hosted by Steven Moe.
  MD

  ["AANZ Expert Session Legal Essentials for Early-Stage Companies", "2026-05-27"] => <<~MD.strip,
    Getting the foundations right: a 90-minute online webinar designed to help startups and early-stage businesses sort their legal foundations from day one. Join Edwin Lim and Sarah Weersing of Hudson Gavin Martin as they cover the key corporate and commercial issues every founder should understand.

    Topics include formalising founder and shareholder arrangements, ensuring your company owns and protects its IP, putting robust contracts in place with suppliers and partners, structuring IP and trading entities, and learning what investors look for in legal due diligence — and how to avoid red flags that can delay or derail a deal. Organised by Angel Association New Zealand.
  MD

  ["KPIs That Drive Profit Presented by Excel in BI NZ", "2026-05-05"] => <<~MD.strip,
    An online session presented by Excel in BI, exploring practical topics across Data, AI, and Automation with a focus on real business application. In this session, you'll learn how to design meaningful KPIs that connect to revenue, margin, and operational efficiency to influence real business outcomes.

    Each Excel in BI session is practical, focused, and designed to deliver real clarity in just one hour. Ideal for curious professionals who want to better understand how data can improve their work, decisions, and career.
  MD

  ["Migrants in Tech", "2026-06-25"] => <<~MD.strip,
    A meetup for migrants based in Tāmaki Makaurau Auckland who are interested in joining the region's growing tech sector. It's a safe space where you can connect with fellow newcomers and the local tech community, share experiences, and build your professional network.

    Whether you're new to New Zealand or have been here a while, this is a welcoming event for anyone navigating the tech industry as a migrant. Held at GridAKL/John Lysaght, 101 Pakenham Street West, Auckland.
  MD

  ["Startup Weekend Taranaki 2026", "2026-07-31"] => <<~MD.strip,
    The 11th iteration of Taranaki's flagship startup event — a 54-hour immersive entrepreneurship experience where you'll apply the skills and life experiences you already have while learning to think, work, and build like a startup. Over an action-packed three days, you'll receive world-class innovation training and meet mentors, potential co-founders, and funders.

    All meals and snacks are provided, and accommodation assistance is available for out-of-town participants. Financial support is available for those who need it, and students receive 50% off with code SWSTUDENT. Bring a laptop or tablet — this could be your start in building Taranaki's or New Zealand's next big success story. At Te W'anake The Foundry, Hāwera.
  MD

  ["Revved. Powerful Minds. Limitless Acceleration.", "2026-08-06"] => <<~MD.strip,
    Not just another business conference — Revved is the beginning of an ongoing movement bringing together 800+ of New Zealand's brightest business minds. From founders and CEOs to industry leaders and rising talent, Revved promises a full day of perspective-shifting content, honest dialogue, and real momentum.

    Speakers include leaders from academyEX, One New Zealand, Air New Zealand, Animation Research Ltd (Sir Ian Taylor), Partners Life, Movac, and more, plus the All Blacks Mental Skills Coach. Held at the Viaduct Events Centre, Auckland.
  MD

  ["CryptoWinter26", "2026-08-25"] => <<~MD.strip,
    New Zealand's premier gathering for the crypto and digital assets ecosystem, bringing together regulators, builders, investors, and enterprise leaders over three days in Queenstown. The theme is "New Zealand Goes Global: Shaping the future of digital assets."

    The programme features a Ministerial keynote, regulatory panels with FMA and RBNZ, masterclasses on compliance, tokenised markets, security, CBDCs, stablecoins, and AI in crypto, plus invite-only policy roundtables and builder-focused sessions. Organised by Blockchain Forum New Zealand and Tech New Zealand at QT Queenstown.
  MD

  ["AUT Innovation Showcase", "2026-09-03"] => <<~MD.strip,
    An inspiring annual event showcasing AUT's emerging research and technologies, and the innovative people making it happen. Explore what Auckland University of Technology is developing — from early-stage research to full-scale prototypes — alongside commercialisation initiatives led by AUT Ventures.

    This is an opportunity to connect with the researchers and innovators behind these projects and discover how AUT's work is translating into real-world impact. All are welcome at AUT City Campus, WZ Building, St Paul's Street. Registration required for catering purposes.
  MD

  ["Aotearoa AI Summit", "2026-09-08"] => <<~MD.strip,
    New Zealand's essential AI gathering, uniting industry leaders, researchers, policymakers, and innovators at Tākina Wellington Convention and Exhibition Centre. The two-day summit features keynotes, panels, and workshops spanning five key themes: AI infrastructure and capability, social licence and trust, workforce transformation, frontier technologies including agentic AI and quantum computing, and real-world adoption and implementation.

    Co-presented by AI Forum New Zealand and Tech New Zealand, the summit explores how AI is transforming sectors including healthcare, finance, agriculture, and government — bringing together Aotearoa's AI community to shape the country's approach to artificial intelligence.
  MD

  ["KiwiSaaS Wellington conference", "2026-09-24"] => <<~MD.strip,
    A day conference for New Zealand's Software-as-a-Service community, hosted by KiwiSaaS in Wellington. KiwiSaaS events bring together SaaS professionals for thought-provoking speakers and opportunities to connect and collaborate with peers from across Aotearoa's growing SaaS sector.

    Details including speakers and specific venue are to be announced. Check the KiwiSaaS website for updates.
  MD

  ["KiwiSaaS Auckland Event", "2026-10-15"] => <<~MD.strip,
    A day event for New Zealand's Software-as-a-Service community, hosted by KiwiSaaS at Pipiri Lane, Wynyard Quarter, Auckland. KiwiSaaS events bring together SaaS professionals for thought-provoking speakers and opportunities to connect and collaborate with peers from across Aotearoa's growing SaaS sector.

    Topic and speakers to be announced. Check the KiwiSaaS website for updates.
  MD

  ["Maui Venture Summit", "2026-11-26"] => <<~MD.strip,
    A one-day summit bringing together Aotearoa's most exciting Māori and Māori-aligned technology founders alongside investors, venture capital firms, iwi, PSGEs, and innovation partners. Expect energy, authenticity, and insight from leaders reimagining what innovation looks like in tomorrow's economy.

    The summit features 10+ high-profile speakers, three expert panel discussions, and keynotes including Sir Ian Taylor (Animation Research Limited). A startup showcase gives up to 10 early-stage, high-growth Māori or Māori-aligned companies the chance to pitch for investment across areas including fusion energy, quantum systems, 3D printing, fintech, and sustainability. Organised by HTK Startup at GridAKL, Wynyard Quarter.
  MD
}

# Read the CSV
csv_content = File.read('data/events.csv')
rows = CSV.parse(csv_content, headers: true)

updated_count = 0
skipped = []

rows.each do |row|
  tech_events_id = row['TechEventsID'].to_s.strip
  next unless tech_events_id.empty?

  title = row['title'].to_s.strip
  start_date = row['start_date'].to_s.strip

  # Try specific match first, then title-only match
  description = SPECIFIC_DESCRIPTIONS[[title, start_date]] || TITLE_DESCRIPTIONS[title]

  if description
    row['ai_description'] = description
    updated_count += 1
    puts "Updated: #{title} (#{start_date})"
  else
    skipped << "#{title} (#{start_date})"
    puts "SKIPPED: #{title} (#{start_date})"
  end
end

# Write back
CSV.open('data/events.csv', 'w') do |csv|
  csv << rows.headers
  rows.each { |row| csv << row }
end

puts "\n--- Summary ---"
puts "Updated: #{updated_count} events"
puts "Skipped: #{skipped.length} events"
skipped.each { |s| puts "  - #{s}" }
