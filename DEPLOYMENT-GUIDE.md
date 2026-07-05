# Mulika Biashara — Deployment Guide
## Complete step-by-step. No developer experience needed.

---

## HOW LOGIN WORKS (no email required)

Staff log in with:
- **Username** — a simple name like `james.k` or `sarah`
- **4-digit PIN** — like an ATM PIN

That is all. No email address. No smartphone. No SMS.

If someone forgets their PIN, they answer a **security question** they chose
when their account was created. No email reset links, no phone codes.

Behind the scenes, the system silently converts `james.k` into
`james.k@mulika.internal` to satisfy the database's technical requirements —
but this is completely hidden. Users never see, type, or need an email address.

---

## FILES IN THIS PACKAGE

| File | What it is |
|------|-----------|
| `index.html` | The app's web page |
| `styles.css` | The app's visual design |
| `app.js` | The app's logic (no secrets inside) |
| `netlify.toml` | Tells Netlify how to deploy |
| `inject-env.sh` | Injects your Supabase keys at deploy time |
| `.gitignore` | Stops secret files being uploaded to GitHub |
| `.env.example` | Template showing which keys are needed |
| `supabase/auth-migration.sql` | Run once in Supabase after the main schema |
| `supabase/functions/onboard-business/` | Creates a new business account |
| `supabase/functions/add-staff-member/` | Adds a staff member to a business |
| `DEPLOYMENT-GUIDE.md` | This file |

---

## STEP 1 — Set up Supabase (10 minutes)

### 1a. Create project
1. Go to https://supabase.com → Sign in → **New project**
2. Name: `mulika-biashara`, Region: **Frankfurt** (closest to Kenya)
3. Set a strong database password and save it somewhere safe
4. Click **Create new project** — wait 2 minutes

### 1b. Get your keys (you will need these in Steps 3 and 4)
1. Click **Settings** (gear icon, bottom left) → **API**
2. Copy and save these — you will need them:

| What | Where to find it | Keep secret? |
|------|-----------------|-------------|
| Project URL | "Project URL" box | No — safe to share |
| anon public key | Under "Project API keys" → anon | No — safe to share |
| service_role key | Under "Project API keys" → service_role | **YES — never share** |

Also go to **Settings → General** and copy the **Reference ID** (looks like `abcdefgh`)

### 1c. Run the main database schema
1. Click **SQL Editor** in the left menu → **New query**
2. Open `mulika_biashara_schema.sql` with Notepad (Windows) or TextEdit (Mac)
3. Select all (Ctrl+A), copy, paste into the SQL editor
4. Click **Run** — you should see "Success. No rows returned."

### 1d. Run the auth migration
1. SQL Editor → **New query** again
2. Open `supabase/auth-migration.sql`, copy all, paste, click **Run**

### 1e. Enable Email login (even though users don't use email — it's a technical requirement)
1. Click **Authentication** in the left menu → **Providers**
2. Find **Email** and click the toggle to turn it **ON**
3. Set **Confirm email** to **OFF**
4. Set **Minimum password length** to `8`
5. Click **Save**

### 1f. Disable email sending (important — our users have no email)
1. **Authentication** → **SMTP Settings**
2. Leave everything blank — no SMTP configured means no emails are ever sent
3. This is correct. Our users recover access via security questions, not email.

---

## STEP 2 — Deploy Edge Functions (15 minutes)

Edge Functions are small programs that run on Supabase's servers.
They handle sensitive operations like creating new business accounts.

### 2a. Install required tools
You need two programs. Open **Terminal** (Mac) or **Command Prompt** (Windows):

Install Node.js first if you don't have it: https://nodejs.org → Download LTS

Then install the Supabase tool:
```
npm install -g supabase
```

### 2b. Log in to Supabase from your computer
```
supabase login
```
A browser window opens — click **Authorize**.

### 2c. Navigate to your project folder
```
cd path/to/mulika-biashara-app
```
(Replace `path/to` with where you extracted the zip)

### 2d. Connect to your Supabase project
```
supabase link --project-ref YOUR_REFERENCE_ID
```
Replace `YOUR_REFERENCE_ID` with the Reference ID from Step 1b.

### 2e. Add your service_role key as a secret
```
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=paste_your_service_role_key_here
```

### 2f. Deploy the two functions
```
supabase functions deploy onboard-business
supabase functions deploy add-staff-member
```
You should see "Deployed successfully" for each.

---

## STEP 3 — Register your first business (5 minutes)

Use a free tool called **Hoppscotch** — open https://hoppscotch.io in your browser.

Set it up like this:
- **Method**: POST
- **URL**: `https://YOUR_PROJECT_REF.supabase.co/functions/v1/onboard-business`
  (Replace YOUR_PROJECT_REF with your Reference ID from Step 1b)
- Under **Headers**, add:
  - `Content-Type` → `application/json`
  - `Authorization` → `Bearer YOUR_ANON_KEY`
- Under **Body** → select **JSON**, paste this (edit the values):

```json
{
  "businessName": "Sparkle Car Wash",
  "vertical": "🚗",
  "ownerUsername": "james.k",
  "ownerDisplayName": "James Kariuki",
  "ownerPin": "1234",
  "securityQuestion": "What was the name of your first shop or business?",
  "securityAnswer": "sparkle"
}
```

Click **Send**.

The response will look like:
```json
{
  "success": true,
  "businessId": "3f2b1c4d-...",
  "message": "Business Sparkle Car Wash created. Username: james.k"
}
```

**Save the businessId** — you will need it in Step 5 for adding more staff.

---

## STEP 4 — Put code on GitHub (5 minutes)

### 4a. Create a GitHub account and repository
1. Go to https://github.com → Sign up (free)
2. Click **+** → **New repository**
3. Name: `mulika-biashara-pos`, set to **Private**, click **Create repository**

### 4b. Upload your files
1. On the repo page, click **uploading an existing file**
2. Drag ALL these files from the `mulika-biashara-app` folder:
   - `index.html`, `styles.css`, `app.js`
   - `netlify.toml`, `inject-env.sh`
   - `.gitignore`, `.env.example`
   - `DEPLOYMENT-GUIDE.md`
   - The entire `supabase/` folder and everything inside it
3. Commit message: `Initial deployment`
4. Click **Commit changes**

**Check:** After uploading, open your repo. You should see `index.html` at the very top level — NOT inside a subfolder. If it is inside a `mulika-biashara-app/` folder, you uploaded the folder instead of the files inside it. Fix by moving each file to the root (click the file → pencil icon → remove the folder prefix from the path → commit).

---

## STEP 5 — Deploy on Netlify (5 minutes)

### 5a. Create a Netlify account and connect GitHub
1. Go to https://netlify.com → Sign up with GitHub (easiest)
2. Click **Add new site** → **Import an existing project** → **GitHub**
3. Select your `mulika-biashara-pos` repository

### 5b. Build settings
On the settings screen:
- **Base directory**: (leave blank)
- **Build command**: `bash inject-env.sh`
- **Publish directory**: `.`

Click **Deploy site**.

### 5c. Add environment variables
While it deploys, go to **Site configuration** → **Environment variables** and add:

| Key | Value |
|-----|-------|
| `SUPABASE_URL` | Your Project URL e.g. `https://abcdef.supabase.co` |
| `SUPABASE_ANON_KEY` | Your anon public key |

Click **Save**.

### 5d. Redeploy with the keys
**Deploys** → **Trigger deploy** → **Deploy site**

Watch the log — look for:
```
Injecting environment variables...
Environment injection complete.
```

### 5e. Update Supabase with your live URL
1. Copy your Netlify URL (e.g. `https://charming-thing-123.netlify.app`)
2. Go to Supabase → **Authentication** → **URL Configuration**
3. Set **Site URL** to your Netlify URL
4. Click **Save**

---

## STEP 6 — Test the full flow (3 minutes)

1. Open your Netlify URL
2. Log in screen appears — no email address field ✅
3. Enter username `james.k` and PIN `1234`
4. You should enter the app as James Kariuki (Checker role)
5. The status badge shows **🟢 Live DB**

**Test recovery:**
1. Click **Forgot PIN?**
2. Enter username `james.k`
3. Your security question appears: "What was the name of your first shop or business?"
4. Type `sparkle` (case doesn't matter)
5. Set a new PIN
6. You are logged in automatically

---

## STEP 7 — Add more staff

Use Hoppscotch again, same setup as Step 3:
- **URL**: `https://YOUR_REF.supabase.co/functions/v1/add-staff-member`
- **Headers**: same as Step 3 — Content-Type + Authorization
- **Body**:
```json
{
  "businessId": "the-business-id-you-saved-in-step-3",
  "staffUsername": "mary.n",
  "staffDisplayName": "Mary Njoki",
  "staffPin": "5678",
  "staffRole": "maker",
  "securityQuestion": "What is your mother's home county or town?",
  "securityAnswer": "Kiambu"
}
```

The staff member can then log in with username `mary.n` and PIN `5678`.
They can change their PIN later via Forgot PIN → security question.

---

## FUTURE UPDATES

When you receive updated code files:
1. Go to your GitHub repo
2. Click the file name → pencil (edit) icon
3. Replace all content with the new version
4. Commit with message e.g. `Update app.js - bug fixes`
5. Netlify redeploys automatically within 60 seconds

---

## SECURITY SUMMARY

| Threat | How it is blocked |
|--------|------------------|
| Stolen credentials | PINs are stretched + salted before storage — the 4-digit PIN alone is useless |
| Account takeover | Security question uses SHA-256 hash — raw answers never stored |
| Cross-business data access | Row Level Security — verified at database level, not just app level |
| Self-registration | No client-side insert on profiles — only Edge Functions can create accounts |
| Sensitive key exposure | service_role key only in Edge Functions — never in browser code |
| Brute-force PIN | Supabase Auth rate-limits failed attempts automatically |
| Session hijacking | HTTPS enforced (HSTS header), sessions managed by Supabase JWT |
| Clickjacking | X-Frame-Options: DENY header |
| Code injection | Content-Security-Policy header restricts script sources |
