#!/bin/bash
# Netlify build script - injects environment variables into app.js
# Set SUPABASE_URL and SUPABASE_ANON_KEY in Netlify > Site Config > Environment Variables
# This script runs before deployment so keys are never in the Git repo.

echo "Injecting environment variables..."

if [ -z "$SUPABASE_URL" ]; then
  echo "WARNING: SUPABASE_URL not set - app will run in offline mode"
  SUPABASE_URL="YOUR_SUPABASE_URL"
fi

if [ -z "$SUPABASE_ANON_KEY" ]; then
  echo "WARNING: SUPABASE_ANON_KEY not set - app will run in offline mode"
  SUPABASE_ANON_KEY="YOUR_SUPABASE_ANON_KEY"
fi

# Replace placeholders in app.js with real values from environment
sed -i "s|YOUR_SUPABASE_URL|${SUPABASE_URL}|g" app.js
sed -i "s|YOUR_SUPABASE_ANON_KEY|${SUPABASE_ANON_KEY}|g" app.js

echo "Environment injection complete."
echo "Supabase URL: ${SUPABASE_URL}"
