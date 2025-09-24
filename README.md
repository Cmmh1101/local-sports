# App Name: Local Sports

# Project structure: 
gameapp/
├─ apps/
│  ├─ mobile/            # Expo (React Native)
│  └─ web/               # Next.js admin/public site
├─ packages/
│  ├─ ui/                # shared UI components
│  └─ lib/               # shared TS models, helpers, API SDK
└─ infra/
   └─ supabase/          # migrations, seed, edge functions
      ├─ migrations/
      └─ functions/