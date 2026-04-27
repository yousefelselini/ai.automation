# Nile Automations SaaS

## Run
cp .env.example .env
npm install
npx prisma migrate dev --name init
npx prisma db seed
npm run dev
