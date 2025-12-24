# GameTracker APP
A mobile-first real-time scoring platform for baseball little leagues across Latin America.

This project aims to become the central platform for teams, leagues, and families in local baseball clubs — starting with Criollitos Baseball League in Venezuela.

# It includes:

- React Native (Expo) mobile app

- Next.js Web App for league/teams admin

- Supabase PostgreSQL backend (DB + Auth + RLS)

- GitHub-integrated CI + Airtable PM system

- Future expansion for league management, standings, live scoring UI, offline scoring, and chat.

# Tech Stack
## Frontend

- React Native + Expo (iOS + Android)

- Next.js (admin dashboard, public pages)

- Shared UI Components in packages/ui

## Backend / Infrastructure

- Supabase (Auth, Database, RLS policies, REST API)

- Edge Functions (when needed)

- SQL Migrations in infra/supabase/migrations

## Developer Tools

- GitHub + Airtable Automations

- Auto-create issues

- Auto-create feature branches

- Auto-create PRs

- Auto-update task status when PR merges

- Postman (testing REST endpoints)

- TypeScript across all layers

- Monorepo structure with shared libraries in packages/lib

# Project Structure
gameapp/
├─ apps/
│  ├─ mobile/            # Expo (React Native)
│  └─ web/               # Next.js admin/public site
├─ packages/
│  ├─ ui/                # Shared components
│  └─ lib/               # Shared models, utils, API wrappers
└─ infra/
   └─ supabase/
      ├─ migrations/     # SQL database migrations
      └─ functions/      # Edge functions (if needed)

# Features Implemented So Far
### Supabase project linked to GitHub & ready for production
### Auth system fully functional

- Register user
- Login
- Retrieve session
- Test users created successfully
- Postman working with tokens saved automatically

### Teams module

- Create team

- Add admin roles

- Region + season_year fields included

- RLS policies in progress

### Project Management Pipeline

- Airtable PM ready

- Task → GitHub Issue automation

- Task → Branch creation

- Task → PR creation

- PR merge → Update Airtable status

### Base API tested with Postman

- Auth endpoints

- Team endpoints

- Team members administration

### Environment Variables

# Create a .env.local file in the root:

SUPABASE_URL="https://<project-ref>.supabase.co"
SUPABASE_ANON_KEY="<anon public key>"
SUPABASE_SERVICE_ROLE="<service role key>"


## To get these values:

- Supabase Dashboard → Settings → API

# Installation & Setup
1. Clone the Repository
git clone https://github.com/Cmmh1101/local-sports.git
cd local-sports

2. Install Dependencies

Using pnpm (recommended):

pnpm install


Or with npm:

npm install

3. Configure Supabase CLI

Install Supabase:

npm install -g supabase


Login:

supabase login


Link the project:

supabase link --project-ref <your-ref>

4. Apply Migrations
cd infra/supabase
supabase db push

Your database is now live with:

Auth enabled

teams table

team_members table

region + season_year support

5️⃣ Test the Backend With Postman

Import your environment:

Key	Value
SUPABASE_URL	https://xxxx.supabase.co

SUPABASE_ANON_KEY	anon key
SUPABASE_SERVICE_ROLE	service role key
ACCESS_TOKEN	(empty)
REFRESH_TOKEN	(empty)
6. Start the Mobile App
cd apps/mobile
pnpm start


Expo will launch with:

iOS simulator

Android simulator

QR code for devices

7. Start the Web App
cd apps/web
pnpm dev

# API Endpoints (Quick Guide)
### Signup (admin mode)
POST {{SUPABASE_URL}}/auth/v1/admin/users

### Login
POST {{SUPABASE_URL}}/auth/v1/token?grant_type=password

### Get Current User
GET {{SUPABASE_URL}}/auth/v1/user

### Create Team
POST {{SUPABASE_URL}}/rest/v1/teams


Body:

{
  "name": "Tigres U12",
  "city": "Porlamar",
  "region": "Nueva Esparta",
  "season_year": 2025
}

🟢 Add Team Member
POST {{SUPABASE_URL}}/rest/v1/team_members

🛠 Development Workflow

# This repo is connected to a full GitHub + Airtable automation system.

## Branching Flow (automatic)

### When a task in Airtable is moved to:

Status	Automation
To Do	GitHub Issue is created
In Progress	Feature branch created
Ready for PR	Pull Request auto-created
Merged	Airtable status → Done

### Developers only need to:

git fetch --all
git checkout feature/my-task-name


### Push code normally:

git commit -m "feat: new thing"
git push


Everything else is automated.

# Future Milestones
## Phase 1 – App Core

- Team creation

- User roles

- Team join requests

- Roster management

## Phase 2 – Games

- Scheduling

- Live scoring

- Offline scoring support

## Phase 3 – Social

- Team chat

- DM

- Parent approvals

- Phase 4 – Leagues

- Regions → Leagues → Teams

- Season standings

# Contact / Contributing

If you'd like to contribute or review the architecture, feel free to open issues or join the discussion.