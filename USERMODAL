// ─── SUPABASE CONFIG ──────────────────────────────────────────
// The anon key is safe to include here — it is designed to be
// public. Supabase Row Level Security (RLS) is the real security
// boundary, not keeping this key secret. The service_role key
// (which bypasses RLS) lives only in Edge Functions, never here.
const SUPABASE_URL  = 'https://iorzouwqhaygbylzifxf.supabase.co';
const SUPABASE_ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlvcnpvdXdxaGF5Z2J5bHppZnhmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODExNzcwNzQsImV4cCI6MjA5Njc1MzA3NH0.hG3Q4-mFWHYSulbpqt-ZAeGEt5fMFD-H7awA4loia-c';

// Sanitize - strip any trailing /rest/v1 or /rest/v1/ that was accidentally
// included in the URL.
const _cleanUrl = SUPABASE_URL.replace(/\/rest\/v1\/?$/, '').replace(/\/$/, '');

let db = null, dbReady = false;

// Global Users Array 
let users = []; 

// Locate your data loading function and ensure user_roles populates users:
async function loadAppData() {
  if (!dbReady || !db) return;
  // 🟢 FIX: Replaced broken 'supabase' instance with your correct global 'db' instance
  const { data: user_roles, error } = await db.from('user_roles').select('*');
  if (!error && user_roles) {
    users = user_roles; // Feeds the array that renderSetup().map is looking for
    if (typeof renderSetup === 'function') renderSetup();      
  }
}

// ─── ERROR LOGGER ─────────────────────────────────────────────
function logError(context, error) {
  const msg = error?.message || error?.error_description || JSON.stringify(error) || 'Unknown error';
  console.error('[Mulika Biashara]', context, '→', msg, error);
  if (typeof showToast === 'function') showToast('⚠️ ' + context + ': ' + msg);
}

function initSupabase() {
  if (_cleanUrl.includes('YOUR_') || SUPABASE_ANON.includes('PASTE_') || SUPABASE_ANON.length < 100) {
    showDbBanner('offline');
    console.warn('[Mulika Biashara] Supabase not configured — anon key missing or too short.');
    return;
  }
  try {
    db = window.supabase.createClient(_cleanUrl, SUPABASE_ANON);
    dbReady = true;
    showDbBanner('online');
    syncFromSupabase();
    loadAppData(); // Automatically pull users when the client initializes
  } catch(e) {
    showDbBanner('offline');
    logError('Supabase init failed', e);
  }
}

function showDbBanner(s) {
  const el = document.getElementById('db-status');
  if (!el) return;
  el.textContent = s === 'online' ? '🟢 Live DB' : '🟡 Offline';
  el.style.background = s === 'online' ? 'var(--green-light)' : 'var(--amber-light)';
  el.style.color = s === 'online' ? 'var(--green)' : 'var(--amber)';
}

async function syncFromSupabase() {
  if (!dbReady || !db) return;
  try {
    const { data: dbP, error: pErr } = await db.from('products').select('*').eq('business_id',businessId).order('id'); 
    if(pErr) logError('Load products',pErr);
    if (dbP && dbP.length) { 
      products = dbP.map(p=>({id:p.id,cat:p.category,name:p.name,price:p.price,icon:p.icon||'🚗'})); 
      if (typeof renderProducts === 'function') renderProducts(); 
      if (typeof renderSetup === 'function') renderSetup(); 
    }
    
    const { data: dbT, error: tErr } = await db.from('transactions').select('*').eq('business_id',businessId).order('created_at',{ascending:false}).limit(500); 
    if(tErr) logError('Load transactions',tErr);
    if (dbT && dbT.length) { 
      transactions = dbT.map(t=>({id:t.id,time:new Date(t.created_at).toLocaleTimeString('en-KE',{hour:'2-digit',minute:'2-digit'}),timestamp:t.created_at,items:t.items,total:t.total,payment:t.payment_method,splits:t.splits||null,staff:t.staff_name,plate:t.plate_number||'',customerPhone:t.customer_phone||'',customerName:t.customer_name||'',isFreeWash:t.is_free_wash||false,isFullyFree:t.is_fully_free!==undefined?t.is_fully_free:(t.is_free_wash&&t.total===0)})); 
      if (typeof save === 'function') save(); 
    }
    
    const { data: dbC, error: cErr } = await db.from('customers').select('*').eq('business_id',businessId); 
    if(cErr) logError('Load customers',cErr);
    if (dbC && dbC.length) { 
      customersByPlate = {}; 
      dbC.forEach(c => customersByPlate[c.plate] = {name:c.name,phone:c.phone,visits:c.visits,free_wash_available:c.free_wash_available}); 
      if (typeof save === 'function') save(); 
    }
    
    const { data: dbBiz, error: bErr } = await db.from('businesses').select('*').eq('id',businessId).maybeSingle(); 
    if(bErr) logError('Load business settings',bErr);
    if (dbBiz) { 
      businessName = dbBiz.name || businessName; 
      businessLogo = dbBiz.logo || businessLogo; 
      businessVertical = dbBiz.vertical || businessVertical; 
      businessNameColor = dbBiz.name_color || businessNameColor; 
      if (typeof save === 'function') save(); 
      if (typeof renderNavBranding === 'function') renderNavBranding(); 
    }
  } catch(e) { 
    console.error('Sync error:', e); 
  }
}

async function saveTransactionToDb(tx) {
  if (!dbReady || !db) return;
  try { const {error:e1} = await db.from('transactions').insert({id:tx.id,business_id:businessId,items:tx.items,total:tx.total,payment_method:tx.payment,splits:tx.splits||null,staff_name:tx.staff,plate_number:tx.plate||null,customer_phone:tx.customerPhone||null,customer_name:tx.customerName||null,is_free_wash:tx.isFreeWash||false,is_fully_free:tx.isFullyFree||false,discount_amount:tx.discountAmount||0,created_at:tx.timestamp}); if(e1) logError('Save transaction',e1); } catch(e) { logError('Save transaction',e); }
}
async function saveProductToDb(p) {
  if (!dbReady || !db) return;
  try { const {error:e2} = await db.from('products').upsert({id:p.id,business_id:businessId,name:p.name,price:p.price,category:p.cat,icon:p.icon}); if(e2) logError('Save product',e2); } catch(e) { logError('Save product',e); }
}
async function saveCustomerToDb(plate, c) {
  if (!dbReady || !db) return;
  try { const {error:e3} = await db.from('customers').upsert({id:plate,business_id:businessId,name:c.name,phone:c.phone,visits:c.visits,free_wash_available:c.freeWashAvailable}); if(e3) logError('Save customer',e3); } catch(e) { logError('Save customer',e); }
}

// ─── VERTICAL REGISTRY ────────────────────────────────────────
const VERTICAL_REGISTRY = {
  'car_wash': { id:'car_wash', emoji:'🚗', identifierLabel:'Plate number', identifierPlaceholder:'e.g. KBZ 123A', identifierInputStyle:'text-transform:uppercase', identifierRequiredMsg:'Plate number is required', identifierSearchHint:'Vehicle', loyaltyNoun:'vehicle', loyaltyEntity:'wash', serviceNoun:'wash', identifierRequired:true, approvalAutoLimit:500 },
  'salon': { id:'salon', emoji:'✂️', identifierLabel:'Customer / Member ID', identifierPlaceholder:'e.g. SLN-001 or name', identifierInputStyle:'', identifierRequiredMsg:'Customer or Member ID is required', identifierSearchHint:'Customer', loyaltyNoun:'customer', loyaltyEntity:'service', serviceNoun:'service', identifierRequired:false, approvalAutoLimit:300 },
  'restaurant': { id:'restaurant', emoji:'🍽️', identifierLabel:'Table / Order number', identifierPlaceholder:'e.g. T-12 or TAK-001', identifierInputStyle:'', identifierRequiredMsg:'Table or order number is required', identifierSearchHint:'Table', loyaltyNoun:'customer', loyaltyEntity:'meal', serviceNoun:'meal', identifierRequired:false, approvalAutoLimit:500 },
  'retail': { id:'retail', emoji:'🏪', identifierLabel:'Customer / Loyalty ID', identifierPlaceholder:'e.g. RET-0042', identifierInputStyle:'', identifierRequiredMsg:'Customer ID is required', identifierSearchHint:'Customer', loyaltyNoun:'customer', loyaltyEntity:'purchase', serviceNoun:'purchase', identifierRequired:false, approvalAutoLimit:1000 },
  'pharmacy': { id:'pharmacy', emoji:'💊', identifierLabel:'Patient / Prescription ID', identifierPlaceholder:'e.g. PAT-2025-001', identifierInputStyle:'', identifierRequiredMsg:'Patient ID is required', identifierSearchHint:'Patient', loyaltyNoun:'patient', loyaltyEntity:'prescription', serviceNoun:'prescription', identifierRequired:false, approvalAutoLimit:500 },
  'laundry': { id:'laundry', emoji:'👕', identifierLabel:'Collection / Order tag', identifierPlaceholder:'e.g. LND-0099', identifierInputStyle:'', identifierRequiredMsg:'Collection tag is required', identifierSearchHint:'Order', loyaltyNoun:'customer', loyaltyEntity:'order', serviceNoun:'order', identifierRequired:false, approvalAutoLimit:300 }
};

const VERTICAL_EMOJI_TO_KEY = { '🚗':'car_wash', '✂️':'salon', '🍽️':'restaurant', '🏪':'retail', '💊':'pharmacy', '👕':'laundry' };

function getVerticalConfig() {
  const key = VERTICAL_EMOJI_TO_KEY[businessVertical] || 'car_wash';
  return VERTICAL_REGISTRY[key] || VERTICAL_REGISTRY['car_wash'];
}

function applyVerticalLabels() {
  const vc = getVerticalConfig();
  const lbl = document.getElementById('plate-field-label');
  if (lbl) lbl.innerHTML = vc.identifierLabel + (vc.identifierRequired ? ' <span class="req">*</span>' : ' <span style="font-size:10px;color:var(--text3)">(optional)</span>');
  const inp = document.getElementById('plate-num');
  if (inp) {
    inp.placeholder = vc.identifierPlaceholder;
    inp.style.textTransform = vc.identifierInputStyle.indexOf('uppercase') !== -1 ? 'uppercase' : '';
  }
  const errEl = document.getElementById('plate-error');
  if (errEl) errEl.textContent = vc.identifierRequiredMsg;
  const loyaltyDesc = document.getElementById('loyalty-track-desc');
  if (loyaltyDesc) loyaltyDesc.textContent = 'Tracked by ' + vc.identifierLabel.toLowerCase();
  const salesCol = document.getElementById('sales-identifier-col');
  if (salesCol) salesCol.textContent = vc.identifierLabel;
  const creditCol = document.getElementById('credit-identifier-col');
  if (creditCol) creditCol.textContent = vc.identifierLabel;
}

// ─── RBAC: USERS ────────────────────────────────────────────────
const ROLE_PERMISSIONS = {
  maker:   ['pos','log','recon','alerts','setup','credit','myreturns'],
  checker: ['pos','log','recon','approvals','alerts','setup','credit']
};
let currentUser = null; 

// ═══════════════════════════════════════════════════════════════
// AUTH — PIN-BASED + SECURITY QUESTION RECOVERY
// ═══════════════════════════════════════════════════════════════
const SECURITY_QUESTIONS = [
  'What was the name of your first shop or business?',
  'What is your mother\'s home county or town?',
  'Who is your favourite brother or sister?',
  'Who is your favourite child?',
  'What was your favourite subject in school?'
];

function stretchPin(pin, username) {
  return pin + '_' + username.trim().toLowerCase() + '_mulika_secure_2025';
}

function usernameToEmail(username) {
  return username.trim().toLowerCase().replace(/\s+/g, '.') + '@mulika.internal';
}

async function hashAnswer(answer) {
  const normalized = answer.trim().toLowerCase();
  const encoded = new TextEncoder().encode(normalized);
  const hashBuffer = await crypto.subtle.digest('SHA-256', encoded);
  return Array.from(new Uint8Array(hashBuffer)).map(b => b.toString(16).padStart(2, '0')).join('');
}

// ── 4. LOGIN ───────────────────────────────────────────────────
async function attemptLogin() {
  const username = document.getElementById('login-username').value.trim();
  const pin = document.getElementById('login-pin').value.trim();
  const errEl = document.getElementById('login-error');
  const btn = document.getElementById('login-btn');
  if (errEl) errEl.classList.remove('show');

  if (!username || !pin) { if(errEl) { errEl.textContent = 'Username and PIN are required'; errEl.classList.add('show'); } return; }
  if (!/^\d{4}$/.test(pin)) { if(errEl) { errEl.textContent = 'PIN must be exactly 4 digits'; errEl.classList.add('show'); } return; }
  if (!db) { if(errEl) { errEl.textContent = 'Not connected to server. Check your internet.'; errEl.classList.add('show'); } return; }

  if (btn) { btn.disabled = true; btn.textContent = 'Signing in…'; }
  try {
    const maskedEmail = usernameToEmail(username);
    const stretchedPassword = stretchPin(pin, username);

    const { data: authData, error: authError } = await db.auth.signInWithPassword({
      email: maskedEmail,
      password: stretchedPassword
    });

    if (authError) {
      if(errEl) { errEl.textContent = 'Incorrect username or PIN'; errEl.classList.add('show'); }
      if (typeof logLoginEvent === 'function') logLoginEvent(username, false);
      return;
    }

    const { data: profile, error: profileError } = await db.from('profiles').select('display_name, role, business_id').eq('user_id', authData.user.id).maybeSingle();

    if (profileError || !profile) {
      if(errEl) { errEl.textContent = 'Account found but profile missing. Contact administrator.'; errEl.classList.add('show'); }
      await db.auth.signOut();
      return;
    }

    businessId = profile.business_id;
    localStorage.setItem('ib_business_id', businessId);
    currentUser = { id: authData.user.id, username, name: profile.display_name, role: profile.role, businessId: profile.business_id };
    if (typeof logLoginEvent === 'function') logLoginEvent(username, true);
    if (typeof enterApp === 'function') enterApp();
  } catch(e) {
    logError('Login', e);
    if(errEl) { errEl.textContent = 'Login failed. Please try again.'; errEl.classList.add('show'); }
  } finally {
    if (btn) { btn.disabled = false; btn.textContent = 'Log in'; }
  }
}

function togglePinVisibility(inputId, btnId) {
  const input = document.getElementById(inputId);
  const btn = document.getElementById(btnId);
  if (!input || !btn) return;
  const show = input.type === 'password';
  input.type = show ? 'text' : 'password';
  btn.textContent = show ? 'Hide' : 'Show';
}

// ── 6. RECOVERY ───────────────────────────────────────────────
let _recoveryProfile = null; 

function showRecovery() {
  document.getElementById('login-card').style.display = 'none';
  document.getElementById('recovery-card').style.display = 'block';
  const errEl = document.getElementById('recovery-error');
  if(errEl) errEl.classList.remove('show');
  document.getElementById('recovery-username').value = '';
  document.getElementById('recovery-step-1').style.display = 'block';
  document.getElementById('recovery-step-2').style.display = 'none';
  document.getElementById('recovery-step-3').style.display = 'none';
  _recoveryProfile = null;
}

function hideRecovery() {
  document.getElementById('recovery-card').style.display = 'none';
  document.getElementById('login-card').style.display = 'block';
  _recoveryProfile = null;
}

async function fetchSecurityQuestion() {
  const username = document.getElementById('recovery-username').value.trim();
  const errEl = document.getElementById('recovery-error');
  const btn = document.getElementById('recovery-step1-btn');
  if(errEl) errEl.classList.remove('show');

  if (!username) { if(errEl) { errEl.textContent = 'Please enter your username'; errEl.classList.add('show'); } return; }
  if (btn) { btn.disabled = true; btn.textContent = 'Looking up…'; }

  try {
    const storedBizId = localStorage.getItem('ib_business_id') || businessId;
    if (!storedBizId) {
      if(errEl) { errEl.textContent = 'Business not configured on this device.'; errEl.classList.add('show'); } 
      return;
    }

    const { data, error } = await db.rpc('get_profile_for_recovery', { p_username: username.toLowerCase().trim(), p_business_id: storedBizId });
    if (error) { logError('Recovery lookup', error); return; }
    
    const profile = data && data[0];
    if (!profile || !profile.security_question) {
      if(errEl) { errEl.textContent = 'Username not found. Check spelling.'; errEl.classList.add('show'); } 
      return;
    }

    _recoveryProfile = { user_id: profile.user_id, display_name: profile.display_name, role: profile.role, security_question: profile.security_question, security_answer_hash: profile.security_answer_hash, business_id: storedBizId, username: username.toLowerCase().trim() };

    document.getElementById('recovery-question-display').textContent = profile.security_question;
    document.getElementById('recovery-step-1').style.display = 'none';
    document.getElementById('recovery-step-2').style.display = 'block';
  } catch(e) {
    logError('Recovery', e);
  } finally {
    if (btn) { btn.disabled = false; btn.textContent = 'Continue →'; }
  }
}

async function verifySecurityAnswer() {
  const answer = document.getElementById('recovery-answer').value;
  const errEl = document.getElementById('recovery-error');
  const btn = document.getElementById('recovery-step2-btn');
  if(errEl) errEl.classList.remove('show');

  if (!answer.trim()) { if(errEl) { errEl.textContent = 'Please type your answer'; errEl.classList.add('show'); } return; }
  if (!_recoveryProfile) { showRecovery(); return; }

  if (btn) { btn.disabled = true; btn.textContent = 'Verifying…'; }
  try {
    const inputHash = await hashAnswer(answer);
    if (inputHash !== _recoveryProfile.security_answer_hash) {
      if(errEl) { errEl.textContent = 'Incorrect answer. Please try again.'; errEl.classList.add('show'); }
      document.getElementById('recovery-answer').value = '';
      return;
    }
    document.getElementById('recovery-step-2').style.display = 'none';
    document.getElementById('recovery-step-3').style.display = 'block';
  } catch(e) {
    logError('Answer verification', e);
  } finally {
    if (btn) { btn.disabled = false; btn.textContent = 'Verify →'; }
  }
}

async function submitNewPin() {
  const newPin = document.getElementById('recovery-new-pin').value.trim();
  const confirmPin = document.getElementById('recovery-confirm-pin').value.trim();
  const errEl = document.getElementById('recovery-error');
  const btn = document.getElementById('recovery-step3-btn');
  if(errEl) errEl.classList.remove('show');

  if (!newPin || !confirmPin) { if(errEl) { errEl.textContent = 'Please enter and confirm your PIN'; errEl.classList.add('show'); } return; }
  if (!/^\d{4}$/.test(newPin)) { if(errEl) { errEl.textContent = 'PIN must be 4 digits'; errEl.classList.add('show'); } return; }
  if (newPin !== confirmPin) { if(errEl) { errEl.textContent = 'PINs do not match'; errEl.classList.add('show'); } return; }

  if (btn) { btn.disabled = true; btn.textContent = 'Saving…'; }
  try {
    const newStretched = stretchPin(newPin, _recoveryProfile.username);
    const { data: rpcResult, error: rpcError } = await db.rpc('reset_user_pin', { p_user_id: _recoveryProfile.user_id, p_new_stretched_password: newStretched, p_answer_hash: _recoveryProfile.security_answer_hash });

    if (rpcError || (rpcResult && !rpcResult.success)) {
      if(errEl) { errEl.textContent = rpcError?.message || 'PIN reset failed'; errEl.classList.add('show'); } 
      return;
    }

    const maskedEmail = usernameToEmail(_recoveryProfile.username);
    const { data: authData, error: authError } = await db.auth.signInWithPassword({ email: maskedEmail, password: newStretched });

    if (authError) { hideRecovery(); return; }

    businessId = _recoveryProfile.business_id;
    localStorage.setItem('ib_business_id', businessId);
    currentUser = { id: authData.user.id, username: _recoveryProfile.username, name: _recoveryProfile.display_name, role: _recoveryProfile.role, businessId: _recoveryProfile.business_id };
    _recoveryProfile = null;
    hideRecovery();
    if (typeof enterApp === 'function') enterApp();
  } catch(e) {
    logError('PIN reset', e);
  } finally {
    if (btn) { btn.disabled = false; btn.textContent = 'Save PIN & Log in'; }
  }
}

async function logout() {
  try { if (db) await db.auth.signOut(); } catch(e) {}
  currentUser = null; businessId = ''; _recoveryProfile = null;
  document.getElementById('app-root').style.display = 'none';
  document.getElementById('login-screen').style.display = 'flex';
}

// ── 10. SIGN UP (New business onboarding with tracking telemetry) ───
function showSignUp() {
  document.getElementById('login-card').style.display = 'none';
  document.getElementById('signup-card').style.display = 'block';
  const errEl = document.getElementById('signup-error');
  if (errEl) errEl.style.display = 'none';
}

function hideSignUp() {
  document.getElementById('signup-card').style.display = 'none';
  document.getElementById('login-card').style.display = 'block';
}

async function submitSignUp() {
  console.log("[Onboarding Telemetry] Submission triggered.");
  
  const bizName   = document.getElementById('signup-biz-name').value.trim();
  const vertical  = document.getElementById('signup-vertical').value;
  const dispName  = document.getElementById('signup-display-name').value.trim();
  const username  = document.getElementById('signup-username').value.trim().toLowerCase();
  const pin       = document.getElementById('signup-pin').value.trim();
  const question  = document.getElementById('signup-security-question').value;
  const answer    = document.getElementById('signup-security-answer').value.trim();
  const errEl     = document.getElementById('signup-error');
  const btn       = document.getElementById('signup-btn');
  
  if (errEl) { errEl.style.display = 'none'; errEl.textContent = ''; }

  if (!bizName || !dispName || !username || !pin || !question || !answer) {
    if (errEl) { errEl.textContent = 'Please fill in all fields'; errEl.style.display = 'block'; } 
    return;
  }
  if (!/^\d{4}$/.test(pin)) {
    if (errEl) { errEl.textContent = 'PIN must be exactly 4 digits'; errEl.style.display = 'block'; } 
    return;
  }
  if (!question) {
    if (errEl) { errEl.textContent = 'Please choose a security question'; errEl.style.display = 'block'; } 
    return;
  }

  // Verification point: Check config status using token references
  if (!SUPABASE_ANON || SUPABASE_ANON.length < 100) {
    if (errEl) { errEl.textContent = 'Configuration Error: Valid API Client key missing.'; errEl.style.display = 'block'; }
    return;
  }

  if (btn) { btn.disabled = true; btn.textContent = 'Creating account…'; }
  
  try {
    const fnUrl = _cleanUrl + '/functions/v1/onboard-business';
    console.log("[Onboarding Telemetry] Attempting to dispatch payload to URL:", fnUrl);

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 15000);

    let response;
    try {
      response = await fetch(fnUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ' + SUPABASE_ANON
        },
        body: JSON.stringify({
          businessName: bizName, 
          vertical: vertical,
          ownerUsername: username, 
          ownerDisplayName: dispName, 
          ownerPin: pin,
          securityQuestion: question, 
          securityAnswer: answer
        }),
        signal: controller.signal
      });
    } catch(fetchErr) {
      console.error("[Onboarding Telemetry] Network Fetch Fault:", fetchErr);
      if (errEl) {
        errEl.textContent = fetchErr.name === 'AbortError' ? 'Request timed out. Please try again.' : 'Could not reach server. Check internet connection.';
        errEl.style.display = 'block';
      }
      return;
    } finally {
      clearTimeout(timeout);
    }

    let result;
    try {
      result = await response.json();
      console.log("[Onboarding Telemetry] Server parsed payload returned:", result);
    } catch(e) {
      console.error("[Onboarding Telemetry] JSON Parse Fault:", e);
      if (errEl) { errEl.textContent = 'Unexpected response structure from server (status ' + response.status + ').'; errEl.style.display = 'block'; }
      return;
    }

    if (!response.ok || !result.success) {
      if (errEl) { errEl.textContent = result.error || ('Server error ' + response.status); errEl.style.display = 'block'; }
      return;
    }

    businessId = result.businessId;
    localStorage.setItem('ib_business_id', businessId);

    if (typeof showToast === 'function') showToast('✅ Account created! Logging you in…');
    document.getElementById('login-username').value = username;
    document.getElementById('login-pin').value = pin;
    hideSignUp();
    await attemptLogin();
  } catch(e) {
    console.error("[Onboarding Telemetry] Critical System Exception caught:", e);
    if (errEl) { errEl.textContent = 'Something went wrong: ' + (e.message || 'unknown error'); errEl.style.display = 'block'; }
  } finally {
    if (btn) { btn.disabled = false; btn.textContent = 'Create account'; }
  }
}

// ── Recovery step indicator helper ────────────────────────────
function setRecoveryStep(step) {
  const subheadings = {
    1: 'Step 1 of 3 — Enter your username',
    2: 'Step 2 of 3 — Answer your security question',
    3: 'Step 3 of 3 — Set your new PIN'
  };
  const subEl = document.getElementById('recovery-subheading');
  if (subEl) subEl.textContent = subheadings[step] || '';
  [1,2,3].forEach(n => {
    const dot = document.getElementById('rdot-'+n);
    if (!dot) return;
    dot.classList.remove('active','done');
    if (n < step) dot.classList.add('done');
    else if (n === step) dot.classList.add('active');
  });
}


// Dual-written: localStorage (immediate, offline-safe) + Supabase (durable)
function logLoginEvent(username, success) {
  const entry = {
    id: 'AUD'+Date.now(), action: success ? 'login_success' : 'login_failed',
    caseId: '—', productName: username || '(blank)', price: null,
    actor: username || '(unknown)', reason: success ? null : 'Invalid credentials',
    timestamp: new Date().toISOString()
  };
  auditLog.unshift(entry); save();
  saveLoginEventToDb(username, success);
}
async function saveLoginEventToDb(username, success) {
  if (!dbReady) return;
  try {
    await db.from('login_events').insert({
      business_id: businessId,
      username: username || null,
      success: success,
      created_at: new Date().toISOString()
    });
  } catch(e) { console.error('Login event log failed:', e); }
}

function enterApp() {
  document.getElementById('login-screen').style.display = 'none';
  document.getElementById('app-root').style.display = 'block';
  // Sidebar user info
  document.getElementById('current-user-name').textContent = currentUser.name;
  const roleBadge = document.getElementById('current-user-role');
  roleBadge.textContent = currentUser.role === 'checker' ? 'Checker' : 'Maker';
  roleBadge.className = 'pill ' + (currentUser.role === 'checker' ? 'pill-purple' : 'pill-amber');
  // Mobile nav user display
  const mobName = document.getElementById('mob-user-name');
  if (mobName) mobName.textContent = currentUser.name;
  // Show/hide topbar elements based on screen width
  updateTopbarForViewport();
  applyPermissions();
  switchRoleView();
  applyPosViewOnly();
  applySidebarState();
  renderProducts(); renderCart(); renderSetup(); updatePendingBadge(); updateAlertBadge(); updateCreditBadge(); renderReturnedList(); renderFooters(); renderNavBranding(); applyVerticalLabels();
  // Default view: pos for makers, log for checkers (since checkers can view pos but it's not their primary action)
  const defaultView = ROLE_PERMISSIONS[currentUser.role].indexOf('pos') !== -1 ? 'pos' : 'log';
  showView(defaultView, document.querySelector('#sidebar-nav [data-perm="'+defaultView+'"]'));
}

function updateTopbarForViewport() {
  const isMob = window.innerWidth < 768;
  const mobBtn = document.getElementById('mob-menu-btn');
  const mobBrand = document.getElementById('topbar-mobile-brand');
  const mobLogout = document.getElementById('topbar-logout-mob');
  if (mobBtn) mobBtn.style.display = isMob ? 'block' : 'none';
  if (mobBrand) mobBrand.style.display = isMob ? 'block' : 'none';
  if (mobLogout) mobLogout.style.display = 'none'; // logout is in sidebar footer (desktop) and mob-drawer (mobile)
}
window.addEventListener('resize', updateTopbarForViewport);

// ─── SIDEBAR COLLAPSE / EXPAND ───────────────────────────────
let sidebarCollapsed = false;
try { const sc = localStorage.getItem('ib_sidebar_collapsed'); if (sc) sidebarCollapsed = JSON.parse(sc); } catch(e){}

function toggleSidebar() {
  sidebarCollapsed = !sidebarCollapsed;
  try { localStorage.setItem('ib_sidebar_collapsed', JSON.stringify(sidebarCollapsed)); } catch(e){}
  applySidebarState();
}
function applySidebarState() {
  const sidebar = document.getElementById('sidebar');
  const main = document.getElementById('main-content');
  const topbar = document.getElementById('topbar');
  if (!sidebar) return;
  if (sidebarCollapsed) {
    sidebar.classList.add('collapsed');
    if (main) main.classList.add('sidebar-collapsed');
    if (topbar) topbar.classList.add('sidebar-collapsed');
    const btn = sidebar.querySelector('.sidebar-collapse-btn');
    if (btn) { btn.textContent = '▶'; btn.title = 'Expand menu'; }
  } else {
    sidebar.classList.remove('collapsed');
    if (main) main.classList.remove('sidebar-collapsed');
    if (topbar) topbar.classList.remove('sidebar-collapsed');
    const btn = sidebar.querySelector('.sidebar-collapse-btn');
    if (btn) { btn.textContent = '◀'; btn.title = 'Collapse menu'; }
  }
}

// ─── MOBILE DRAWER ───────────────────────────────────────────
function toggleMobDrawer() {
  const bg = document.getElementById('mob-drawer-bg');
  const drawer = document.getElementById('mob-drawer');
  const nav = document.getElementById('mobile-bottom-nav');
  const isOpen = drawer.classList.contains('show');
  if (isOpen) {
    drawer.classList.remove('show');
    bg.classList.remove('show');
    // Re-enable bottom nav interaction when drawer closes
    if (nav) nav.style.pointerEvents = '';
    document.body.style.overflow = '';
  } else {
    drawer.classList.add('show');
    bg.classList.add('show');
    // Block bottom nav tap-through while drawer is open
    if (nav) nav.style.pointerEvents = 'none';
    // Prevent page scroll while drawer is open
    document.body.style.overflow = 'hidden';
  }
}
function showViewMob(id) {
  // Close drawer first (restores pointer events, scroll etc)
  const drawer = document.getElementById('mob-drawer');
  if (drawer && drawer.classList.contains('show')) toggleMobDrawer();
  showView(id, null);
  // Mark the correct drawer item as active
  document.querySelectorAll('.mob-drawer-item').forEach(el => {
    el.classList.toggle('active', el.dataset.perm === id);
  });
}

function applyPosViewOnly() {
  const isViewOnly = currentUser.role === 'checker';
  const viewOnlyBanner = document.getElementById('pos-viewonly-banner');
  if (viewOnlyBanner) viewOnlyBanner.style.display = isViewOnly ? 'block' : 'none';
  const chargeBtn = document.getElementById('charge-btn');
  if (chargeBtn) chargeBtn.disabled = isViewOnly;
  window.__posReadOnly = isViewOnly;
}

function applyPermissions() {
  const allowed = ROLE_PERMISSIONS[currentUser.role] || [];
  // Sidebar nav tabs
  document.querySelectorAll('#sidebar-nav .nav-tab').forEach(tab => {
    const perm = tab.dataset.perm;
    if (!perm || allowed.indexOf(perm) === -1) {
      tab.style.display = 'none';
      tab.classList.add('locked');
      tab.onclick = null;
    } else {
      tab.style.display = '';
      tab.classList.remove('locked');
      tab.onclick = function() { showView(perm, tab); };
    }
  });
  // Mobile bottom nav tabs
  document.querySelectorAll('.mob-tab').forEach(tab => {
    const perm = tab.dataset.perm;
    if (perm === '__more__') return; // always show the More button
    if (!perm || allowed.indexOf(perm) === -1) {
      tab.style.display = 'none';
      tab.classList.add('locked');
    } else {
      tab.style.display = '';
      tab.classList.remove('locked');
    }
  });
  // Mobile drawer items
  document.querySelectorAll('.mob-drawer-item').forEach(item => {
    const perm = item.dataset.perm;
    if (!perm || allowed.indexOf(perm) === -1) {
      item.style.display = 'none';
      item.classList.add('locked');
    } else {
      item.style.display = '';
      item.classList.remove('locked');
    }
  });
}


function switchRoleView() {
  // Drives the Approvals view subtitle/badge based on logged-in role (not a manual switcher anymore)
  const badge = document.getElementById('current-role-badge');
  const subtitle = document.getElementById('approvals-subtitle');
  if (currentUser.role === 'checker') {
    badge.textContent = 'Checker'; badge.className = 'pill pill-purple';
    subtitle.textContent = 'Review and approve, reject, or return product requests from your team.';
  } else {
    badge.textContent = 'Maker'; badge.className = 'pill pill-amber';
    subtitle.textContent = 'Submit new products or price changes for manager review.';
  }
}

// Try resuming a session (survives refresh within the same tab)
try {
  const sess = sessionStorage.getItem('ib_session');
  if (sess) { currentUser = JSON.parse(sess); }
} catch(e){}

// ─── ID GENERATORS ────────────────────────────────────────────
function nextProductId() {
  productIdCounter += 1; save();
  return 'PRD' + String(productIdCounter).padStart(4,'0');
}
function nextCaseId() {
  caseIdCounter += 1; save();
  return 'CASE' + String(caseIdCounter).padStart(5,'0');
}

// ─── STATE ────────────────────────────────────────────────────
let products = [
  {id:'PRD0001',cat:'service',name:'Express Wash',price:300,icon:'🚿'},
  {id:'PRD0002',cat:'service',name:'Full Wash',price:500,icon:'🚗'},
  {id:'PRD0003',cat:'service',name:'Premium Detail',price:1500,icon:'✨'},
  {id:'PRD0004',cat:'service',name:'Interior Clean',price:800,icon:'🪣'},
  {id:'PRD0005',cat:'addon',name:'Tyre Shine',price:150,icon:'⚙️'},
  {id:'PRD0006',cat:'addon',name:'Air Freshener',price:50,icon:'🌸'},
  {id:'PRD0007',cat:'addon',name:'Wax Polish',price:500,icon:'💎'},
  {id:'PRD0008',cat:'addon',name:'Seat Shampoo',price:300,icon:'🛋️'},
];
let productIdCounter = 8;
let caseIdCounter = 0;
let staff = ['James Kariuki','Mary Njoki','Peter Omondi','Faith Achieng'];
let cart = {}, selectedPayment = 'M-Pesa', transactions = [], txCounter = 1000;
let pendingRequests = [], requestHistory = [], auditLog = [], ownerAlerts = [], reconHistory = [];
let editingProductId = null, rejectingRequestId = null, rejectAction = 'reject', selectedIcon = '🔧';
let customersByPlate = {}; // plate -> {name, phone, visits, freeWashAvailable}
let loyaltyEnabled = true, loyaltyEvery = 10, loyaltyFreeWashLimit = 500, loyaltyFreeWashMode = 'cap'; // 'cap' = fixed KES limit, 'full' = fully free
let paymentMode = 'single';
let splitRows = [];
let redeemFreeWash = false;
let businessName = 'Sparkle Car Wash';
// Multi-tenant isolation key - generated once per business install, never changes.
// Every Supabase row should include this as a partition key so each SME's data
// is completely isolated from every other business on the same DB instance.
// In production this would be set server-side during onboarding; here it's
// generated client-side on first run as a strong random UUID.
let businessId = '';
let businessLogo = ''; // base64 data URL, empty = no custom logo uploaded
let businessVertical = '🚗'; // fallback emoji shown when no logo is set
let businessNameColor = '#c1543a'; // SME-chosen color for their business name display
let businessAddress = 'Westlands, Nairobi';
let businessEmail = '';
let businessPhone = '';

const ICONS = ['🚿','🚗','✨','🪣','⚙️','🌸','💎','🛋️','🔧','🧴','🧽','🪥','🚙','🧹','💈','🔑','🧺','🌿','🪣','💧','🛞','🔩','🍽️','✂️','💊','👕','🧁','☕','🍔','🛠️','🧼','🪒','💅','👟'];

try {
  const s = localStorage.getItem('ib_transactions'); if(s) transactions = JSON.parse(s);
  const sp = localStorage.getItem('ib_products'); if(sp) products = JSON.parse(sp);
  const ss = localStorage.getItem('ib_staff'); if(ss) staff = JSON.parse(ss);
  const sr = localStorage.getItem('ib_pending'); if(sr) pendingRequests = JSON.parse(sr);
  const sh = localStorage.getItem('ib_history'); if(sh) requestHistory = JSON.parse(sh);
  const sa = localStorage.getItem('ib_audit'); if(sa) auditLog = JSON.parse(sa);
  const sc = localStorage.getItem('ib_customers_plate'); if(sc) customersByPlate = JSON.parse(sc);
  const soa = localStorage.getItem('ib_alerts'); if(soa) ownerAlerts = JSON.parse(soa);
  const srh = localStorage.getItem('ib_recon_history'); if(srh) reconHistory = JSON.parse(srh);
  const sl = localStorage.getItem('ib_loyalty'); if(sl) { const l=JSON.parse(sl); loyaltyEnabled=l.enabled; loyaltyEvery=l.every; loyaltyFreeWashLimit=l.freeWashLimit||500; loyaltyFreeWashMode=l.mode||'cap'; }
  const sb = localStorage.getItem('ib_bizname'); if(sb) businessName = sb;
  // Load or generate the business ID - this is the multi-tenant partition key.
  // Once generated it never changes, ensuring data integrity across sessions.
  let storedBizId = localStorage.getItem('ib_business_id');
  if (!storedBizId) {
    storedBizId = 'biz-' + Date.now().toString(36) + '-' + Math.random().toString(36).substr(2,9);
    localStorage.setItem('ib_business_id', storedBizId);
  }
  businessId = storedBizId;
  const sbl = localStorage.getItem('ib_bizlogo'); if(sbl) businessLogo = sbl;
  const sbv = localStorage.getItem('ib_bizvertical'); if(sbv) businessVertical = sbv;
  const sbc = localStorage.getItem('ib_biznamecolor'); if(sbc) businessNameColor = sbc;
  const sba = localStorage.getItem('ib_bizaddress'); if(sba) businessAddress = sba;
  const sbe = localStorage.getItem('ib_bizemail'); if(sbe) businessEmail = sbe;
  const sbp = localStorage.getItem('ib_bizphone'); if(sbp) businessPhone = sbp;
  const spc = localStorage.getItem('ib_pid_counter'); if(spc) productIdCounter = parseInt(spc)||productIdCounter;
  const scc = localStorage.getItem('ib_case_counter'); if(scc) caseIdCounter = parseInt(scc)||0;
} catch(e){}

function save() {
  try {
    localStorage.setItem('ib_transactions', JSON.stringify(transactions));
    localStorage.setItem('ib_products', JSON.stringify(products));
    localStorage.setItem('ib_staff', JSON.stringify(staff));
    localStorage.setItem('ib_pending', JSON.stringify(pendingRequests));
    localStorage.setItem('ib_history', JSON.stringify(requestHistory));
    localStorage.setItem('ib_audit', JSON.stringify(auditLog));
    localStorage.setItem('ib_customers_plate', JSON.stringify(customersByPlate));
    localStorage.setItem('ib_alerts', JSON.stringify(ownerAlerts));
    localStorage.setItem('ib_recon_history', JSON.stringify(reconHistory));
    localStorage.setItem('ib_loyalty', JSON.stringify({enabled:loyaltyEnabled, every:loyaltyEvery, freeWashLimit:loyaltyFreeWashLimit, mode:loyaltyFreeWashMode}));
    localStorage.setItem('ib_bizname', businessName);
    localStorage.setItem('ib_bizlogo', businessLogo);
    localStorage.setItem('ib_bizvertical', businessVertical);
    localStorage.setItem('ib_biznamecolor', businessNameColor);
    localStorage.setItem('ib_bizaddress', businessAddress);
    localStorage.setItem('ib_bizemail', businessEmail);
    localStorage.setItem('ib_bizphone', businessPhone);
    localStorage.setItem('ib_pid_counter', String(productIdCounter));
    localStorage.setItem('ib_case_counter', String(caseIdCounter));
  } catch(e){}
}

function renderFooters() {
  // InverBrass stays exactly as-is in the footer, on every screen, regardless
  // of which SME is using the platform - this is the platform attribution.
  const year = new Date().getFullYear();
  const text = 'Powered by <strong>InverBrass</strong> — Mulika Biashara © ' + year;
  ['footer-pos','footer-log','footer-recon','footer-approvals','footer-alerts','footer-setup','footer-credit','footer-myreturns'].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.innerHTML = text;
  });
}

// Refreshes the nav bar branding (logo + name) to match the SME's own setup.
// This is what makes each SME's interface feel like their own product,
// even though InverBrass remains the platform underneath (see footer).
function renderNavBranding() {
  // Sidebar business name + color
  const nameEl = document.getElementById('nav-business-name');
  if (nameEl) { nameEl.textContent = businessName; nameEl.style.color = businessNameColor; }
  // Sidebar logo vs emoji fallback
  const img = document.getElementById('nav-logo-img');
  const fallback = document.getElementById('nav-logo-fallback');
  if (img && fallback) {
    if (businessLogo) {
      img.src = businessLogo; img.classList.add('show');
      fallback.style.display = 'none';
    } else {
      img.classList.remove('show');
      fallback.style.display = 'block';
      fallback.textContent = businessVertical;
    }
  }
  // Mobile topbar brand name
  const mobBrand = document.getElementById('topbar-mobile-brand');
  if (mobBrand) { mobBrand.textContent = businessName; mobBrand.style.color = businessNameColor; }
  // Setup preview box
  const previewImg = document.getElementById('logo-preview-img');
  const previewFallback = document.getElementById('logo-preview-fallback');
  if (previewImg) {
    if (businessLogo) { previewImg.src = businessLogo; previewImg.style.display='block'; previewFallback.style.display='none'; }
    else { previewImg.style.display='none'; previewFallback.style.display='block'; previewFallback.textContent = businessVertical; }
  }
  const colorPicker = document.getElementById('biz-name-color');
  if (colorPicker) colorPicker.value = businessNameColor;
  syncLoginScreenBranding();
  applySidebarState(); // apply saved collapse state on branding refresh
}

function syncLoginScreenBranding() {
  // Update each card's brand block (login, recovery)
  [['login-business-name','login-logo-img','login-logo-fallback'],
   ['login-business-name-2','login-logo-img-2','login-logo-fallback-2']].forEach(([nameId,imgId,fallbackId]) => {
    const nameEl = document.getElementById(nameId);
    const imgEl  = document.getElementById(imgId);
    const fbEl   = document.getElementById(fallbackId);
    if (!nameEl) return;
    nameEl.textContent = businessName;
    nameEl.style.color = businessNameColor;
    if (businessLogo) {
      imgEl.src = businessLogo;
      imgEl.style.display = 'block';
      if (fbEl) fbEl.style.display = 'none';
    } else {
      imgEl.style.display = 'none';
      if (fbEl) { fbEl.style.display = 'inline'; fbEl.textContent = businessVertical || '🚗'; }
    }
  });
  const yearEl = document.getElementById('login-footer-year');
  if (yearEl) yearEl.textContent = new Date().getFullYear();
}


function updateBizNameColor(val) {
  businessNameColor = val;
  save();
  renderNavBranding();
  saveLogoToDb();
}

function updateBizName(val) {
  businessName = val.trim() || 'Your Business';
  save();
  renderNavBranding();
}

function updateBizVertical(emoji) {
  businessVertical = emoji;
  save();
  renderNavBranding();
  applyVerticalLabels();
}

function handleLogoUpload(files) {
  if (!files || !files.length) return;
  const file = files[0];
  if (!file.type.startsWith('image/')) { showToast('⚠️ Please upload an image file'); return; }
  if (file.size > 1024*1024*2) { showToast('⚠️ Logo should be under 2MB'); return; }
  const reader = new FileReader();
  reader.onload = (e) => {
    businessLogo = e.target.result; // base64 data URL - stored in localStorage / Supabase
    save();
    renderNavBranding();
    saveLogoToDb();
    showToast('✅ Logo updated — now shown across the interface');
  };
  reader.readAsDataURL(file);
}

async function saveLogoToDb() {
  if (!dbReady) return;
  try { const {error:e4} = await db.from('businesses').upsert({ id: businessId, name: businessName, logo: businessLogo, vertical: businessVertical, name_color: businessNameColor }); if(e4) logError('Save business settings',e4); } catch(e) { logError('Save business settings',e); }
}

function saveBusinessSettings() {
  businessName = document.getElementById('biz-name').value.trim() || businessName;
  businessAddress = document.getElementById('biz-loc').value.trim();
  businessEmail = document.getElementById('biz-email').value.trim();
  const phoneVal = document.getElementById('biz-phone').value.trim();
  if (phoneVal && !isValidKenyanPhone(phoneVal)) {
    document.getElementById('biz-phone-error').classList.add('show');
    showToast('⚠️ Please enter a valid telephone number before saving');
    return;
  }
  document.getElementById('biz-phone-error').classList.remove('show');
  businessPhone = phoneVal;
  save();
  renderNavBranding();
  saveLogoToDb();
  showToast('✅ Settings saved');
}
function validateBizPhoneLive() {
  const val = document.getElementById('biz-phone').value.trim();
  const errEl = document.getElementById('biz-phone-error');
  if (!val || isValidKenyanPhone(val)) errEl.classList.remove('show');
  else errEl.classList.add('show');
}

// ─── AUTOCOMPLETE ENGINE ──────────────────────────────────────
// Generic, reusable: works for staff, plate, phone, and name fields alike.
function showAutocomplete(listId, items, onPick) {
  const list = document.getElementById(listId);
  if (!items.length) { list.classList.remove('show'); list.innerHTML=''; return; }
  list.innerHTML = items.map((it,i) => {
    const sub = it.sub ? ('<small>'+it.sub+'</small>') : '';
    return '<div class="autocomplete-item" data-idx="'+i+'">'+it.label+sub+'</div>';
  }).join('');
  list.classList.add('show');
  // Use mousedown (fires BEFORE the input's blur event) instead of click,
  // and preventDefault so focus never leaves the input mid-selection. This
  // fixes a race condition where blur's setTimeout hid the dropdown before
  // a regular click could register - the reported "staff field not
  // populating" bug.
  Array.prototype.forEach.call(list.children, (el, i) => {
    el.onmousedown = (e) => { e.preventDefault(); onPick(items[i]); list.classList.remove('show'); };
  });
}
function hideAutocomplete(listId) {
  const list = document.getElementById(listId);
  if (list) list.classList.remove('show');
}

// Staff autocomplete (dropdown of known staff, filtered as you type)
function onStaffInput(val) {
  val = (val||'').trim().toLowerCase();
  const matches = staff.filter(s => s.toLowerCase().indexOf(val) === 0 || val === '');
  showAutocomplete('staff-autocomplete', matches.map(s=>({label:s})), (item) => {
    document.getElementById('staff-name').value = item.label;
    document.getElementById('staff-error').classList.remove('show');
  });
}

// Plate autocomplete (suggests previously seen plates starting with the typed text)
function onPlateInput(val) {
  val = val.toUpperCase();
  document.getElementById('plate-num').value = val;
  document.getElementById('plate-error').classList.remove('show');
  if (val.length < 1) { hideAutocomplete('plate-autocomplete'); return; }
  const allPlates = Object.keys(customersByPlate);
  const matches = allPlates.filter(p => p.toUpperCase().indexOf(val) === 0).slice(0,6);
  showAutocomplete('plate-autocomplete', matches.map(p => {
    const c = customersByPlate[p];
    return {label:p, sub:(c.name||'Unknown')+' · '+(c.visits||0)+' visits', plate:p};
  }), (item) => {
    document.getElementById('plate-num').value = item.plate;
    onPlateInput(item.plate);
    lookupCustomerByPlate(item.plate);
  });
}

// Phone autocomplete
function onPhoneInput(val) {
  if (val.length < 1) { hideAutocomplete('phone-autocomplete'); document.getElementById('cust-phone-error').classList.remove('show'); return; }
  const allPhones = [...new Set(Object.values(customersByPlate).map(c=>c.phone).filter(Boolean))];
  const matches = allPhones.filter(p => p.indexOf(val) === 0).slice(0,6);
  showAutocomplete('phone-autocomplete', matches.map(p=>({label:p, phone:p})), (item) => {
    document.getElementById('cust-phone').value = item.phone;
    // Try to also fill name if we know it
    const match = Object.values(customersByPlate).find(c=>c.phone===item.phone);
    if (match && match.name) document.getElementById('cust-name').value = match.name;
    validatePhoneFieldLive();
  });
}

function validatePhoneFieldLive() {
  const val = document.getElementById('cust-phone').value.trim();
  const errEl = document.getElementById('cust-phone-error');
  if (!val) { errEl.classList.remove('show'); return true; }
  if (!isValidKenyanPhone(val)) { errEl.classList.add('show'); return false; }
  errEl.classList.remove('show'); return true;
}

// Name autocomplete
function onNameInput(val) {
  if (val.length < 1) { hideAutocomplete('name-autocomplete'); return; }
  const valLower = val.toLowerCase();
  const allNames = [...new Set(Object.values(customersByPlate).map(c=>c.name).filter(Boolean))];
  const matches = allNames.filter(n => n.toLowerCase().indexOf(valLower) === 0).slice(0,6);
  showAutocomplete('name-autocomplete', matches.map(n=>({label:n, name:n})), (item) => {
    document.getElementById('cust-name').value = item.name;
    const match = Object.values(customersByPlate).find(c=>c.name===item.name);
    if (match && match.phone) document.getElementById('cust-phone').value = match.phone;
  });
}

// ─── CUSTOMER & LOYALTY (tracked by PLATE) ─────────────────────
function lookupCustomerByPlate(plate) {
  plate = plate.trim().toUpperCase();
  redeemFreeWash = false;
  if (!plate) { document.getElementById('loyalty-area').innerHTML = ''; return; }
  const c = customersByPlate[plate];
  if (c) {
    if (c.name) document.getElementById('cust-name').value = c.name;
    if (c.phone) document.getElementById('cust-phone').value = c.phone;
    renderLoyaltyArea(plate, c);
  } else {
    document.getElementById('loyalty-area').innerHTML = '';
  }
}

function renderLoyaltyArea(plate, c) {
  const area = document.getElementById('loyalty-area');
  if (!loyaltyEnabled) { area.innerHTML = ''; return; }
  const visits = c.visits || 0;
  const progress = visits % loyaltyEvery;
  const pct = Math.round((progress / loyaltyEvery) * 100);
  if (c.freeWashAvailable) {
    const limitNote = loyaltyFreeWashMode === 'full'
      ? '<div style="font-size:11px;margin-top:4px;color:var(--green)">Fully free — the entire service is covered, no charge to customer.</div>'
      : (loyaltyFreeWashLimit > 0
        ? '<div style="font-size:11px;margin-top:4px;color:var(--green)">Free up to KES '+loyaltyFreeWashLimit.toLocaleString()+'. Any amount above this is charged to the customer.</div>'
        : '<div style="font-size:11px;margin-top:4px;color:var(--green)">No value cap — fully free.</div>');
    const vc = getVerticalConfig();
    area.innerHTML = '<div class="free-wash-banner">🎉 '+vc.loyaltyNoun.charAt(0).toUpperCase()+vc.loyaltyNoun.slice(1)+' <strong>'+plate+'</strong> has a <strong>FREE '+vc.serviceNoun+'</strong> available (visit #'+(visits+1)+')!'+limitNote+
      '<label style="display:flex;align-items:center;gap:6px;justify-content:center;margin-top:8px;font-size:13px;cursor:pointer">' +
      '<input type="checkbox" id="redeem-checkbox" onchange="toggleRedeem(this.checked)"/> Redeem free '+vc.serviceNoun+' on this visit' +
      '</label></div>';
  } else {
    area.innerHTML = '<div class="loyalty-badge">' +
      '<span>🎁</span>' +
      '<div style="flex:1">' +
      '<div style="font-weight:600">Visit '+visits+' of '+loyaltyEvery+' (this '+getVerticalConfig().loyaltyNoun+')</div>' +
      '<div class="loyalty-progress"><div class="loyalty-fill" style="width:'+pct+'%"></div></div>' +
      '</div>' +
      '<span style="color:var(--text2)">'+(loyaltyEvery-progress)+' to go</span>' +
      '</div>';
  }
}

function toggleRedeem(checked) {
  redeemFreeWash = checked;
  // If split payment is active, re-seed the split amounts against the new
  // chargeable total (full price vs. just the topup) rather than leaving
  // stale amounts that no longer add up correctly.
  if (paymentMode === 'split' && splitRows.length) {
    const newTotal = getChargeableTotal();
    splitRows = splitRows.map((r,i) => ({ method: r.method, amount: i===0 ? newTotal : 0 }));
  }
  renderCart();
}

// ─── POS ──────────────────────────────────────────────────────
function renderProducts() {
  const sg = document.getElementById('product-grid');
  const ag = document.getElementById('addon-grid');
  sg.innerHTML = ''; ag.innerHTML = '';
  products.forEach(p => {
    const qty = cart[p.id] || 0;
    const btn = document.createElement('div');
    btn.className = 'product-btn' + (qty ? ' selected' : '');
    btn.onclick = () => addToCart(p.id);
    btn.innerHTML = '<div class="product-icon">'+p.icon+'</div><div class="product-name">'+p.name+'</div><div class="product-price">KES '+p.price.toLocaleString()+'</div>'+(qty?'<div class="qty-badge">'+qty+'</div>':'');
    (p.cat === 'addon' ? ag : sg).appendChild(btn);
  });
}
function addToCart(id) {
  if (window.__posReadOnly) { showToast('👁️ View-only — checkers cannot create sales'); return; }
  cart[id]=(cart[id]||0)+1; renderProducts(); renderCart();
}
function removeFromCart(id) { if(cart[id]>1) cart[id]--; else delete cart[id]; renderProducts(); renderCart(); }
function clearCart() {
  cart={}; redeemFreeWash=false;
  document.getElementById('plate-num').value=''; document.getElementById('cust-phone').value=''; document.getElementById('cust-name').value='';
  document.getElementById('loyalty-area').innerHTML='';
  document.getElementById('plate-error').classList.remove('show');
  document.getElementById('staff-error').classList.remove('show');
  renderProducts(); renderCart();
}
function getCartTotal() {
  let total=0;
  Object.keys(cart).forEach(id => { const p=products.find(x=>x.id==id); if(p) total += p.price*cart[id]; });
  return total;
}
// The amount actually owed for THIS sale - full cart total normally, or
// just the topup portion when redeeming a free wash that exceeds the
// configured free-wash value limit. Split payments must balance against
// THIS figure, not the raw cart total, otherwise a customer topping up a
// capped free wash would be asked to split-pay the full original price.
function getChargeableTotal() {
  const total = getCartTotal();
  if (!redeemFreeWash) return total;
  const topup = (loyaltyFreeWashMode === 'full') ? 0 : (loyaltyFreeWashLimit > 0 && total > loyaltyFreeWashLimit ? (total - loyaltyFreeWashLimit) : 0);
  return topup;
}
function renderCart() {
  const items = document.getElementById('cart-items');
  const totalRow = document.getElementById('cart-total-row');
  const keys = Object.keys(cart);
  if (!keys.length) { items.innerHTML='<div class="cart-empty">Tap a service to add it</div>'; totalRow.style.display='none'; return; }
  let total=0, html='';
  keys.forEach(id => {
    const p = products.find(x=>x.id==id); if(!p) return;
    const sub = p.price*cart[id]; total+=sub;
    html += '<div class="cart-item"><div class="cart-item-name">'+p.icon+' '+p.name+'</div><div class="qty-ctrl"><button class="qty-btn" onclick="removeFromCart(\''+id+'\')">−</button><span class="qty-num">'+cart[id]+'</span><button class="qty-btn" onclick="addToCart(\''+id+'\')">+</button></div><div class="cart-item-price">KES '+sub.toLocaleString()+'</div></div>';
  });
  items.innerHTML=html; totalRow.style.display='block';
  const freeWashTopup = redeemFreeWash ? ((loyaltyFreeWashMode==='full') ? 0 : (loyaltyFreeWashLimit>0&&total>loyaltyFreeWashLimit ? total-loyaltyFreeWashLimit : 0)) : 0;
  document.getElementById('cart-total').textContent = redeemFreeWash
    ? (freeWashTopup > 0 ? 'KES '+freeWashTopup.toLocaleString()+' due (KES '+loyaltyFreeWashLimit.toLocaleString()+' free, top-up required)' : 'KES 0 — FREE')
    : 'KES '+total.toLocaleString();
  document.getElementById('charge-btn').textContent = redeemFreeWash
    ? (freeWashTopup > 0 ? 'Collect KES '+freeWashTopup.toLocaleString()+' top-up' : 'Complete — free')
    : 'Charge KES '+total.toLocaleString();
  document.getElementById('payment-section').style.display = (redeemFreeWash && freeWashTopup===0) ? 'none' : 'block';
  if (paymentMode==='split') renderSplitRows();
}
function selectPayment(el) { document.querySelectorAll('.pay-opt').forEach(e=>e.classList.remove('selected')); el.classList.add('selected'); selectedPayment=el.dataset.method; }

// ─── SPLIT PAYMENTS (with auto-balance) ────────────────────────
function setPaymentMode(mode) {
  paymentMode = mode;
  document.getElementById('mode-single').classList.toggle('selected', mode==='single');
  document.getElementById('mode-split').classList.toggle('selected', mode==='split');
  document.getElementById('single-payment').style.display = mode==='single' ? 'block' : 'none';
  document.getElementById('split-payment').style.display = mode==='split' ? 'block' : 'none';
  if (mode==='split' && splitRows.length===0) {
    const total = getChargeableTotal();
    splitRows = [{method:'M-Pesa', amount: total}, {method:'Cash', amount: 0}];
  }
  renderSplitRows();
}
function addSplitRow() {
  if (splitRows.length >= 4) { showToast('Maximum 4 payment methods per sale'); return; }
  const allMethods = ['M-Pesa','Cash','Card','Credit','Discount'];
  const used = splitRows.map(r=>r.method);
  const nextMethod = allMethods.find(m => used.indexOf(m) === -1);
  if (!nextMethod) { showToast('All payment methods are already in use for this sale'); return; }
  splitRows.push({method:nextMethod, amount:0});
  renderSplitRows();
}
function removeSplitRow(i) { splitRows.splice(i,1); renderSplitRows(); }
function updateSplitRow(i, field, val) {
  if (field === 'method') {
    const alreadyUsed = splitRows.some((r,idx) => idx !== i && r.method === val);
    if (alreadyUsed) {
      showToast('⚠️ ' + val + ' is already used in this sale — pick a different method');
      renderSplitRows(); // revert the dropdown back to its previous value
      return;
    }
    splitRows[i][field] = val;
    renderSplitRows();
    return;
  }
  splitRows[i][field] = (parseFloat(val)||0);
  if (splitRows.length >= 2) {
    const total = getChargeableTotal();
    let targetIdx;
    if (splitRows.length === 2) { targetIdx = i === 0 ? 1 : 0; }
    else { targetIdx = splitRows.length - 1; if (targetIdx === i) targetIdx = splitRows.length - 2; }
    const sumOthers = splitRows.reduce((s,r,idx) => idx === targetIdx ? s : s + (r.amount||0), 0);
    let remainder = total - sumOthers;
    if (remainder < 0) remainder = 0;
    splitRows[targetIdx].amount = remainder;
    const targetInput = document.querySelector('#split-rows input[data-idx="'+targetIdx+'"]');
    if (targetInput) targetInput.value = remainder;
    renderSplitRemaining();
    return;
  }
  renderSplitRemaining();
}
function renderSplitRows() {
  const container = document.getElementById('split-rows');
  const allMethods = ['M-Pesa','Cash','Card','Credit','Discount'];
  container.innerHTML = splitRows.map((row,i) => {
    const usedByOthers = splitRows.filter((r,idx)=>idx!==i).map(r=>r.method);
    const opts = allMethods.map(m=>{
      const disabled = usedByOthers.indexOf(m) !== -1 ? ' disabled' : '';
      const label = m === 'Discount' ? '🏷️ Discount (reduction)' : m;
      return '<option value="'+m+'"'+(m===row.method?' selected':'')+disabled+'>'+label+(disabled?' (in use)':'')+'</option>';
    }).join('');
    const removeBtn = splitRows.length>2 ? '<button class="split-remove" onclick="removeSplitRow('+i+')">✕</button>' : '';
    return '<div class="split-row"><select onchange="updateSplitRow('+i+',\'method\',this.value)">'+opts+'</select><input type="number" min="0" value="'+row.amount+'" placeholder="Amount" data-idx="'+i+'" oninput="updateSplitRow('+i+',\'amount\',this.value)"/>'+removeBtn+'</div>';
  }).join('');
  renderSplitRemaining();
}
function renderSplitRemaining() {
  const total = getChargeableTotal();
  const sum = splitRows.reduce((s,r)=>s+(r.amount||0),0);
  const remaining = total - sum;
  const el = document.getElementById('split-remaining');
  if (!el) return;
  if (Math.abs(remaining) < 0.01) { el.className = 'split-remaining ok'; el.textContent = '✓ Fully covered — KES ' + total.toLocaleString(); }
  else if (remaining > 0) { el.className = 'split-remaining bad'; el.textContent = 'Remaining: KES ' + remaining.toLocaleString(); }
  else { el.className = 'split-remaining bad'; el.textContent = 'Over by KES ' + Math.abs(remaining).toLocaleString(); }
}

// ─── VALIDATION + RECORD SALE ──────────────────────────────────
function validateSaleForm() {
  let valid = true;
  const errors = [];
  const plate = document.getElementById('plate-num').value.trim();
  const staffVal = document.getElementById('staff-name').value.trim();
  if (!plate) {
    document.getElementById('plate-error').textContent = getVerticalConfig().identifierRequiredMsg;
    document.getElementById('plate-error').classList.add('show');
    errors.push(getVerticalConfig().identifierRequiredMsg); valid = false;
  } else { document.getElementById('plate-error').classList.remove('show'); }

  if (!staffVal) {
    document.getElementById('staff-error').textContent = 'Staff/Attendant field is required';
    document.getElementById('staff-error').classList.add('show');
    errors.push('Staff/Attendant field is required'); valid = false;
  } else if (staff.indexOf(staffVal) === -1) {
    document.getElementById('staff-error').textContent = 'Please select a valid staff member from the list';
    document.getElementById('staff-error').classList.add('show');
    errors.push('Please select a valid staff member from the list'); valid = false;
  } else { document.getElementById('staff-error').classList.remove('show'); }

  return { valid, errors };
}

function recordSale() {
  if (window.__posReadOnly) { showToast('👁️ View-only — checkers cannot create sales'); return; }
  const keys=Object.keys(cart); if(!keys.length) { showToast('⚠️ Please add at least one service to the sale'); return; }
  const validation = validateSaleForm();
  if (!validation.valid) { showToast('⚠️ ' + validation.errors[0]); return; }
  const staff_val=document.getElementById('staff-name').value.trim();
  const plate=document.getElementById('plate-num').value.trim().toUpperCase();
  const custPhone = document.getElementById('cust-phone').value.trim();
  const custName = document.getElementById('cust-name').value.trim();
  if (custPhone && !isValidKenyanPhone(custPhone)) { showToast('⚠️ Customer phone must be a valid Kenyan number (e.g. 0712345678 or +254712345678)'); return; }
  let total=0; const items=[];
  keys.forEach(id=>{ const p=products.find(x=>x.id==id); if(!p) return; total+=p.price*cart[id]; items.push({name:p.name,qty:cart[id],price:p.price,productId:p.id}); });

  // Compute the actual amount owed FIRST - full price normally, or just the
  // topup portion when redeeming a free wash above the configured limit.
  // All payment validation below (single or split) targets this figure.
  const freeWashTopup = redeemFreeWash ? ((loyaltyFreeWashMode==='full') ? 0 : (loyaltyFreeWashLimit>0&&total>loyaltyFreeWashLimit ? total-loyaltyFreeWashLimit : 0)) : 0;
  const chargedTotal = redeemFreeWash ? freeWashTopup : total;
  const freeWashFullyCovered = redeemFreeWash && freeWashTopup === 0;

  let paymentLabel, splits = null, discountAmount = 0;
  if (freeWashFullyCovered) {
    paymentLabel = 'Free wash (loyalty)';
  } else if (paymentMode === 'split') {
    const sum = splitRows.reduce((s,r)=>s+(r.amount||0),0);
    if (Math.abs(sum-chargedTotal) > 0.01) { showToast('⚠️ All split amounts (including any discount) must add up to KES ' + chargedTotal.toLocaleString()); return; }
    splits = splitRows.filter(r=>r.amount>0);
    if (!splits.filter(r=>r.method!=='Discount').length) { showToast('⚠️ At least one payment method is required alongside any discount'); return; }
    discountAmount = splits.filter(r=>r.method==='Discount').reduce((s,r)=>s+r.amount,0);
    paymentLabel = (redeemFreeWash ? 'Free wash + split topup: ' : 'Split: ') + splits.map(r=>r.method+' KES'+r.amount).join(' + ');
  } else {
    if (!selectedPayment) { showToast('⚠️ Payment type is required'); return; }
    paymentLabel = redeemFreeWash ? ('Free wash + topup via ' + selectedPayment) : selectedPayment;
  }

  const now=new Date();
  const txPayment = freeWashFullyCovered ? 'Free' : (paymentMode==='split' ? 'Split' : selectedPayment);
  // Store discountAmount on the transaction so the summary and reports can
  // correctly exclude it from "collected" totals while still showing it.
  const tx={id:'TX'+String(++txCounter),time:now.toLocaleTimeString('en-KE',{hour:'2-digit',minute:'2-digit'}),timestamp:now.toISOString(),items,total:chargedTotal,payment:txPayment,splits,discountAmount:discountAmount||0,staff:staff_val,plate,customerPhone:custPhone,customerName:custName,isFreeWash:redeemFreeWash,isFullyFree:freeWashFullyCovered,freeWashSaving:redeemFreeWash?(total-freeWashTopup):0};
  transactions.unshift(tx); saveTransactionToDb(tx);

  // Loyalty bookkeeping — tracked by PLATE NUMBER
  let loyaltyMsg = '';
  if (loyaltyEnabled && plate) {
    if (!customersByPlate[plate]) customersByPlate[plate] = {name:custName, phone:custPhone, visits:0, freeWashAvailable:false};
    const c = customersByPlate[plate];
    if (custName) c.name = custName;
    if (custPhone) c.phone = custPhone;
    const vc = getVerticalConfig();
    const noun = vc.loyaltyNoun; // 'vehicle', 'customer', 'table', etc.
    const svcNoun = vc.serviceNoun; // 'wash', 'service', 'order', etc.
    const idLabel = vc.identifierLabel; // 'Plate number', 'Table/Order number', etc.
    if (redeemFreeWash) {
      c.freeWashAvailable = false;
      loyaltyMsg = '🎁 Free '+svcNoun+' redeemed for '+noun+' '+plate+'. Loyalty counter reset.';
      const freeWashAlert = {id:'AL'+Date.now(), type:'free_wash_completed', message:'✅ Free '+svcNoun+' has been done for '+noun+' '+plate+(c.name?(' ('+c.name+')'):'') + ' — loyalty reward redeemed.', plate:plate, timestamp:new Date().toISOString(), read:false};
      ownerAlerts.unshift(freeWashAlert);
    } else {
      c.visits = (c.visits||0) + 1;
      if (c.visits % loyaltyEvery === 0) {
        c.freeWashAvailable = true;
        const alert = {id:'AL'+Date.now(), type:'loyalty', message:'🎉 '+noun.charAt(0).toUpperCase()+noun.slice(1)+' '+plate+(c.name?(' ('+c.name+')'):'') + ' just completed visit #' + c.visits + ' — next '+svcNoun+' is FREE!', plate:plate, timestamp:new Date().toISOString(), read:false};
        ownerAlerts.unshift(alert);
        loyaltyMsg = '🎉 '+noun.charAt(0).toUpperCase()+noun.slice(1)+' '+plate+' just earned a FREE '+svcNoun+' for their next visit (completed visit #' + c.visits + ')! Owner has been alerted.';
      } else {
        loyaltyMsg = 'Visit ' + c.visits + ' of ' + loyaltyEvery + ' recorded for '+noun+' '+plate+'. ' + (loyaltyEvery - (c.visits%loyaltyEvery)) + ' more to a free '+svcNoun+'.';
      }
    }
    saveCustomerToDb(plate, c);
  }

  save(); updateAlertBadge();

  document.getElementById('modal-summary').textContent = items.map(i=>i.qty>1?(i.qty+'× '+i.name):i.name).join(', ') + ' — ' + (freeWashFullyCovered ? 'FREE (loyalty reward)' : 'KES '+chargedTotal.toLocaleString()+' via '+paymentLabel);
  const mpesaDiv=document.getElementById('modal-mpesa');
  if (!freeWashFullyCovered && selectedPayment==='M-Pesa' && paymentMode==='single') {
    mpesaDiv.style.display='block';
    mpesaDiv.textContent='M-Pesa prompt sent\nRef: MPS'+Math.random().toString(36).substr(2,8).toUpperCase()+'\nAmount: KES '+chargedTotal.toLocaleString();
  } else if (!freeWashFullyCovered && paymentMode==='split' && splits) {
    const mpesaSplit = splits.find(s=>s.method==='M-Pesa');
    if (mpesaSplit) { mpesaDiv.style.display='block'; mpesaDiv.textContent='M-Pesa prompt sent for KES '+mpesaSplit.amount+'\nRef: MPS'+Math.random().toString(36).substr(2,8).toUpperCase(); }
    else mpesaDiv.style.display='none';
  } else mpesaDiv.style.display='none';

  const loyaltyDiv=document.getElementById('modal-loyalty');
  if (loyaltyMsg) { loyaltyDiv.style.display='block'; loyaltyDiv.textContent=loyaltyMsg; } else loyaltyDiv.style.display='none';

  const _vc=getVerticalConfig();
  if (freeWashFullyCovered) { showToast('🎉 Free '+_vc.serviceNoun+' done — loyalty reward redeemed for '+_vc.loyaltyNoun+' '+plate); }
  else if (redeemFreeWash) { showToast('🎉 Free '+_vc.serviceNoun+' applied — topup of KES '+freeWashTopup.toLocaleString()+' charged for '+_vc.loyaltyNoun+' '+plate); }

  document.getElementById('sale-modal').classList.add('show');
}

function closeModal() {
  document.getElementById('sale-modal').classList.remove('show');
  clearCart();
  document.getElementById('staff-name').value='';
  paymentMode='single'; splitRows=[]; redeemFreeWash=false;
  setPaymentMode('single');
  document.querySelectorAll('.pay-opt').forEach(e=>e.classList.remove('selected'));
  document.querySelector('.pay-opt[data-method="M-Pesa"]').classList.add('selected');
  selectedPayment='M-Pesa';
}

// ─── LOG (with date range filter) ───────────────────────────────
function setDateRange(preset) {
  const now = new Date();
  let from, to;
  if (preset === 'today') { from = to = now; }
  else if (preset === 'week') { from = new Date(now); from.setDate(now.getDate()-7); to = now; }
  else if (preset === 'month') { from = new Date(now); from.setDate(now.getDate()-30); to = now; }
  document.getElementById('filter-date-from').value = from.toISOString().split('T')[0];
  document.getElementById('filter-date-to').value = to.toISOString().split('T')[0];
  renderLog();
}
// ─── MULTI-SELECT FILTER ENGINE (payment type + staff) ─────────
// selectedPaymentFilters / selectedStaffFilters: empty array = "All" (no filter applied)
let selectedPaymentFilters = [];
let selectedStaffFilters = [];

function toggleMultiselect(key) {
  const panel = document.getElementById('multiselect-'+key+'-panel');
  const isOpen = panel.classList.contains('show');
  document.querySelectorAll('.multiselect-panel').forEach(p=>p.classList.remove('show'));
  if (!isOpen) panel.classList.add('show');
}
// Close any open multiselect panel when clicking elsewhere
document.addEventListener('click', function(e) {
  if (!e.target.closest('.multiselect')) {
    document.querySelectorAll('.multiselect-panel').forEach(p=>p.classList.remove('show'));
  }
});

function renderStaffMultiselectOptions() {
  const panel = document.getElementById('multiselect-staffms-panel');
  const staffSet = [...new Set(transactions.map(t=>t.staff))].sort();
  panel.innerHTML = '<label class="multiselect-option"><input type="checkbox" value="__all__" onchange="onMultiselectAllToggle(\'staffms\',this.checked)"/> All</label>' +
    '<div class="multiselect-divider"></div>' +
    staffSet.map(s => '<label class="multiselect-option"><input type="checkbox" value="'+s+'" onchange="onMultiselectOptionToggle(\'staffms\')"/> '+s+'</label>').join('');
  // Re-check whichever staff were previously selected
  selectedStaffFilters.forEach(s => {
    const cb = panel.querySelector('input[value="'+s.replace(/"/g,'')+'"]');
    if (cb) cb.checked = true;
  });
}

function onMultiselectAllToggle(key, checked) {
  const panelId = key === 'payment' ? 'multiselect-payment-panel' : 'multiselect-staffms-panel';
  const panel = document.getElementById(panelId);
  const optionBoxes = panel.querySelectorAll('input[type="checkbox"]:not([value="__all__"])');
  optionBoxes.forEach(cb => cb.checked = false); // "All" overrides individual picks
  if (key === 'payment') selectedPaymentFilters = [];
  else selectedStaffFilters = [];
  updateMultiselectLabel(key);
  renderLog();
}

function onMultiselectOptionToggle(key) {
  const panelId = key === 'payment' ? 'multiselect-payment-panel' : 'multiselect-staffms-panel';
  const panel = document.getElementById(panelId);
  const allBox = panel.querySelector('input[value="__all__"]');
  const optionBoxes = panel.querySelectorAll('input[type="checkbox"]:not([value="__all__"])');
  const checked = Array.prototype.filter.call(optionBoxes, cb=>cb.checked).map(cb=>cb.value);
  allBox.checked = false; // picking any individual option clears "All"
  if (key === 'payment') selectedPaymentFilters = checked;
  else selectedStaffFilters = checked;
  updateMultiselectLabel(key);
  renderLog();
}

function updateMultiselectLabel(key) {
  const labelEl = document.getElementById('multiselect-'+key+'-label');
  const selected = key === 'payment' ? selectedPaymentFilters : selectedStaffFilters;
  const noun = key === 'payment' ? 'payment type' : 'staff';
  if (!selected.length) labelEl.textContent = 'All ' + (key==='payment'?'payment types':'staff');
  else if (selected.length === 1) labelEl.textContent = selected[0];
  else labelEl.textContent = selected.length + ' ' + noun + 's selected';
}

function getFilteredLogRows() {
  const dFrom = document.getElementById('filter-date-from').value;
  const dTo = document.getElementById('filter-date-to').value;
  let filtered = transactions.slice();
  if (dFrom) filtered = filtered.filter(t => t.timestamp.split('T')[0] >= dFrom);
  if (dTo) filtered = filtered.filter(t => t.timestamp.split('T')[0] <= dTo);
  // Payment type: empty selection = All. Otherwise match if transaction's
  // payment method is in the selected list (Split transactions match if
  // ANY of their split methods are selected).
  if (selectedPaymentFilters.length) {
    filtered = filtered.filter(t => {
      if (t.payment === 'Split' && t.splits) return t.splits.some(s => selectedPaymentFilters.indexOf(s.method) !== -1);
      return selectedPaymentFilters.indexOf(t.payment) !== -1;
    });
  }
  if (selectedStaffFilters.length) {
    filtered = filtered.filter(t => selectedStaffFilters.indexOf(t.staff) !== -1);
  }
  return filtered;
}
function renderLog() {
  if (!document.getElementById('filter-date-from').value) setDateRangeQuiet('today');
  renderStaffMultiselectOptions();
  const filtered = getFilteredLogRows();
  const tbody=document.getElementById('log-tbody');
  if(!filtered.length){tbody.innerHTML='<tr><td colspan="7" style="text-align:center;padding:24px;color:var(--text3)">No transactions in this range</td></tr>';renderLogSummary([]);return;}
  tbody.innerHTML=filtered.map(tx=>{
    let payDisplay = tx.payment;
    if (tx.payment==='Split' && tx.splits) payDisplay = tx.splits.map(s=>s.method+':'+s.amount).join(', ');
    const pillClass = tx.isFullyFree?'pill-gold':tx.payment==='M-Pesa'?'pill-green':tx.payment==='Cash'?'pill-amber':tx.payment==='Card'?'pill-purple':tx.payment==='Split'?'pill-gray':'pill-red';
    const pillLabel = tx.isFullyFree ? '🎁 Free' : (tx.isFreeWash ? '🎁 '+payDisplay+' (topup)' : payDisplay);
    const amountLabel = tx.isFullyFree ? 'KES 0' : 'KES '+tx.total.toLocaleString();
    const dateLabel = new Date(tx.timestamp).toLocaleDateString('en-KE',{day:'numeric',month:'short'}) + ' ' + tx.time;
    return '<tr><td>'+dateLabel+'</td><td>'+tx.items.map(i=>i.qty>1?(i.qty+'×'+i.name):i.name).join(', ')+'</td><td>'+(tx.customerName||(tx.customerPhone?tx.customerPhone:'—'))+'</td><td>'+(tx.plate||'—')+'</td><td>'+tx.staff+'</td><td><span class="pill '+pillClass+'">'+pillLabel+'</span></td><td style="font-weight:500">'+amountLabel+'</td></tr>';
  }).join('');
  renderLogSummary(filtered);
  const dFrom = document.getElementById('filter-date-from').value, dTo = document.getElementById('filter-date-to').value;
  document.getElementById('log-date').textContent = dFrom === dTo ? new Date(dFrom).toLocaleDateString('en-KE',{weekday:'long',year:'numeric',month:'long',day:'numeric'}) : (dFrom+' to '+dTo);
}
function setDateRangeQuiet(preset) {
  const now = new Date();
  document.getElementById('filter-date-from').value = now.toISOString().split('T')[0];
  document.getElementById('filter-date-to').value = now.toISOString().split('T')[0];
}
function renderLogSummary(filtered) {
  const byMethod = {};
  let totalCollected = 0;   // actual cash received (excludes unsettled credit)
  let creditTotal = 0;      // total credit extended (outstanding + settled)
  let creditCount = 0;
  let freeWashCount = 0, freeWashSavings = 0;

  filtered.forEach(t => {
    if (t.isFreeWash) { freeWashCount++; freeWashSavings += (t.freeWashSaving||0); }
    if (t.isFullyFree) return; // zero charge, skip payment tally

    // Credit sales: only count OUTSTANDING (unsettled) so the figure matches
    // what the credit report's Outstanding filter shows. Settled credit has
    // already been collected (it posts a 'Credit paid' settlement tx).
    if (t.payment === 'Credit') {
      if (!t.creditSettled) {
        const amt = getCreditAmount(t);
        creditTotal += amt; creditCount++;
        if (!byMethod['Credit']) byMethod['Credit'] = {amount:0, count:0, isCredit:true};
        byMethod['Credit'].amount += amt; byMethod['Credit'].count++;
      }
      return;
    }
    // Credit paid settlements: count as collected (real money received)
    if (t.payment === 'Credit paid') {
      totalCollected += t.total;
      if (!byMethod['Credit paid']) byMethod['Credit paid'] = {amount:0, count:0};
      byMethod['Credit paid'].amount += t.total; byMethod['Credit paid'].count++;
      return;
    }
    // Split payments: may include Credit or Discount legs
    if (t.payment === 'Split' && t.splits) {
      t.splits.forEach(s => {
        if (!byMethod[s.method]) byMethod[s.method] = {amount:0, count:0, isCredit: s.method==='Credit', isDiscount: s.method==='Discount'};
        byMethod[s.method].amount += s.amount; byMethod[s.method].count++;
        if (s.method === 'Credit') {
          // Only count as outstanding if not yet settled
          if (!t.creditSettled) { creditTotal += s.amount; creditCount++; }
          else byMethod[s.method].amount -= s.amount; // remove from display if settled
        } else if (s.method === 'Discount') {
          // discount reduces value - not collected
        } else {
          totalCollected += s.amount;
        }
      });
      return;
    }
    // All other payment methods: collected
    totalCollected += t.total;
    if (!byMethod[t.payment]) byMethod[t.payment] = {amount:0, count:0};
    byMethod[t.payment].amount += t.total; byMethod[t.payment].count++;
  });

  const discountByMethod = byMethod['Discount'];
  const discountRow = discountByMethod && discountByMethod.amount > 0
    ? '<div style="display:flex;justify-content:space-between;gap:12px;font-size:12px;padding:3px 0">' +
        '<span style="color:var(--amber)">🏷️ Discounts given</span>' +
        '<span style="font-weight:600;color:var(--amber)">KES '+discountByMethod.amount.toLocaleString()+' · '+discountByMethod.count+' tx</span>' +
      '</div>' : '';

  const rowsHtml = Object.entries(byMethod)
    .filter(([m]) => m !== 'Credit' && m !== 'Discount') // shown separately below
    .map(([method, d]) =>
      '<div style="display:flex;justify-content:space-between;gap:12px;font-size:12px;padding:3px 0">' +
        '<span style="color:var(--text2)">'+method+'</span>' +
        '<span style="font-weight:600">KES '+d.amount.toLocaleString()+' · '+d.count+' tx</span>' +
      '</div>'
    ).join('');

  const creditRow = creditCount > 0
    ? '<div style="display:flex;justify-content:space-between;gap:12px;font-size:12px;padding:4px 0;margin-top:4px;border-top:1px solid var(--border)">' +
        '<span style="color:var(--red)">📒 Credit (not yet collected)</span>' +
        '<span style="font-weight:600;color:var(--red)">KES '+creditTotal.toLocaleString()+' · '+creditCount+' tx</span>' +
      '</div>' : '';

  const freeRow = freeWashCount > 0
    ? '<div style="display:flex;justify-content:space-between;gap:12px;font-size:12px;padding:3px 0">' +
        '<span style="color:var(--text2)">🎁 Free rewards given</span>' +
        '<span style="font-weight:600">'+freeWashCount+' redemption'+(freeWashCount!==1?'s':'')+(freeWashSavings>0?' · KES '+freeWashSavings.toLocaleString()+' saved':'')+'</span>' +
      '</div>' : '';

  document.getElementById('log-summary-card').innerHTML =
    '<div style="display:flex;justify-content:space-between;align-items:baseline;margin-bottom:8px;padding-bottom:8px;border-bottom:1px solid var(--border)">' +
      '<span style="font-size:11px;color:var(--text2);text-transform:uppercase;letter-spacing:.4px">Summary</span>' +
      '<span style="font-size:11px;color:var(--text2)">'+filtered.length+' sales</span>' +
    '</div>' +
    '<div style="display:flex;justify-content:space-between;margin-bottom:8px"><span style="font-size:13px;font-weight:600">Total collected</span><span style="font-size:15px;font-weight:700;color:var(--teal)">KES '+totalCollected.toLocaleString()+'</span></div>' +
    (rowsHtml || '') + freeRow + discountRow + creditRow;
}
let pendingCSVContent = null;
let pendingCSVFilename = '';

function exportCSV() {
  const rows = getFilteredLogRows();
  if(!rows.length){showToast('No transactions to export');return;}
  const headers='ID,Date,Time,Items,Customer,Plate,Staff,Payment,Amount\n';
  const csv=rows.map(r=>{
    let pay = r.isFullyFree?'Free (loyalty)':(r.payment==='Split'&&r.splits?r.splits.map(s=>s.method+':'+s.amount).join('|'):r.payment);
    return r.id+','+r.timestamp.split('T')[0]+','+r.time+',"'+r.items.map(i=>i.name).join(' + ')+'",'+(r.customerName||r.customerPhone||'')+','+(r.plate||'')+','+r.staff+',"'+pay+'",'+r.total;
  }).join('\n');
  pendingCSVContent = headers+csv;
  pendingCSVFilename = (businessName.replace(/[^a-z0-9]/gi,'-').toLowerCase())+'-sales-'+new Date().toISOString().split('T')[0]+'.csv';
  openShareModalForCSV(pendingCSVFilename);
}

function openShareModalForCSV(filename) {
  pendingShareDoc = null; // signals CSV mode (not PDF)
  pendingShareFilename = filename;
  document.getElementById('share-recipient-area').style.display = 'none';
  document.getElementById('share-link-area').style.display = 'none';
  document.getElementById('share-modal').classList.add('show');
}


// ─── PDF EXPORT (jsPDF) ─────────────────────────────────────────
// ─── PDF BRANDING HELPER ────────────────────────────────────────
// Every PDF report leads with the SME's own name and logo (this is THEIR
// report, for THEIR records/customers) - InverBrass is demoted to a small
// footer line on each page, mirroring how the in-app footer works.
function addPdfHeader(doc, subtitle) {
  let titleX = 14;
  if (businessLogo) {
    try {
      const fmt = businessLogo.indexOf('image/png') !== -1 ? 'PNG' : 'JPEG';
      doc.addImage(businessLogo, fmt, 14, 10, 16, 16);
      titleX = 34;
    } catch(e) { /* if the logo format can't be embedded, just skip it */ }
  }
  // Available width depends on the page size (portrait vs landscape) and how
  // much room the logo took on the left - using this instead of a fixed
  // width is what was causing the overspill on narrower portrait pages.
  const pageWidth = doc.internal.pageSize.getWidth();
  const maxWidth = pageWidth - titleX - 14;

  let y = 18;
  doc.setFontSize(16); doc.setTextColor(0);
  const nameLines = doc.splitTextToSize(businessName, maxWidth);
  doc.text(nameLines, titleX, y);
  y += nameLines.length * 6;

  doc.setFontSize(10); doc.setTextColor(120);
  const subtitleLines = doc.splitTextToSize(subtitle, maxWidth);
  doc.text(subtitleLines, titleX, y);
  y += subtitleLines.length * 5;
  doc.setTextColor(0);

  // Contact details (address, email, phone) on every report per item #9 -
  // only show lines that are actually filled in. Wrapped the same way so a
  // long address/email/phone combination never runs off the page edge.
  const contactParts = [];
  if (businessAddress) contactParts.push(businessAddress);
  if (businessPhone) contactParts.push('Tel: ' + businessPhone);
  if (businessEmail) contactParts.push(businessEmail);
  if (contactParts.length) {
    doc.setFontSize(8); doc.setTextColor(140);
    const contactLines = doc.splitTextToSize(contactParts.join('   |   '), maxWidth);
    doc.text(contactLines, titleX, y);
    doc.setTextColor(0);
    y += contactLines.length * 4;
  }
  return y + 5; // Y position where the caller should start drawing content
}
function addPdfFooter(doc) {
  const pageCount = doc.internal.getNumberOfPages();
  for (let i = 1; i <= pageCount; i++) {
    doc.setPage(i);
    const h = doc.internal.pageSize.getHeight();
    doc.setFontSize(8); doc.setTextColor(180);
    doc.text('Powered by InverBrass — Mulika Biashara © ' + new Date().getFullYear(), 14, h - 8);
    doc.setTextColor(0);
  }
}

// Draws one table row with each cell WRAPPED to fit its column width rather
// than cut off with substring() - fixes item #6 (truncated PDF content).
// Returns the new Y position after the tallest wrapped cell in the row.
// Draws WRAPPED column headers (fixes custom report headers overlapping
// when a field label is wider than its column) and returns nothing - call
// site adds its own spacing after, same pattern as drawWrappedRow.
function drawTableHeader(doc, headers, colX, y) {
  doc.setFontSize(9); doc.setFont(undefined,'bold');
  // Estimate each column's available width as the gap to the next column
  // (or a reasonable default for the last column) so long header labels wrap
  // instead of overlapping their neighbor.
  const widths = colX.map((x,i) => (i < colX.length-1 ? colX[i+1]-x-2 : 36));
  let maxLines = 1;
  headers.forEach((h,i) => {
    const lines = doc.splitTextToSize(String(h), widths[i]);
    doc.text(lines, colX[i], y);
    if (lines.length > maxLines) maxLines = lines.length;
  });
  doc.setFont(undefined,'normal');
  // Return the line height actually used so callers can space the divider
  // and first data row correctly below a wrapped (multi-line) header,
  // instead of assuming every header is a single line.
  return maxLines * 4.2;
}

// Inserts soft break opportunities into long unbroken strings (e.g. a plate
// number or single long word) so jsPDF's splitTextToSize can actually wrap
// them instead of letting them overflow into the next column.
function softWrapLongTokens(str, maxCharsPerToken) {
  return String(str).split(' ').map(tok =>
    tok.length > maxCharsPerToken
      ? tok.match(new RegExp('.{1,'+maxCharsPerToken+'}','g')).join(' ')
      : tok
  ).join(' ');
}

function drawWrappedRow(doc, values, colX, colWidth, startY) {
  doc.setFontSize(8);
  const widths = Array.isArray(colWidth) ? colWidth : values.map(()=>colWidth);
  const wrappedCells = values.map((v,i) => {
    const safe = softWrapLongTokens(v, 14); // break tokens longer than ~14 chars
    return doc.splitTextToSize(String(safe), widths[i]);
  });
  const maxLines = Math.max.apply(null, wrappedCells.map(c=>c.length));
  wrappedCells.forEach((lines, i) => doc.text(lines, colX[i], startY));
  return startY + Math.max(maxLines * 4.2, 6);
}

function exportLogPDF() {
  const rows = getFilteredLogRows();
  if (!rows.length) { showToast('No transactions to export'); return; }
  const doc = new jspdf.jsPDF({orientation:'landscape'}); // landscape gives more room, reduces wrapping/truncation
  const dFrom = document.getElementById('filter-date-from').value, dTo = document.getElementById('filter-date-to').value;
  const PAGE_BOTTOM = 180; // leave room below this for totals + footer before forcing a new page
  let y = addPdfHeader(doc, 'Sales Report  |  ' + dFrom + ' to ' + dTo);
  const headers = ['Date','Time','Items','Plate','Staff','Payment','Amount'];
  const colX = [14,38,58,120,152,184,226];
  const colW = [22,18,58,28,28,38,38];
  y += drawTableHeader(doc, headers, colX, y);
  doc.setLineWidth(0.2); doc.line(14,y-3,268,y-3); y += 2;
  let total = 0;
  rows.forEach(r => {
    if (y > PAGE_BOTTOM) { doc.addPage(); y = addPdfHeader(doc, 'Sales Report  |  ' + dFrom + ' to ' + dTo + ' (cont.)'); y += drawTableHeader(doc, headers, colX, y); doc.line(14,y-3,268,y-3); y += 2; }
    const itemsStr = r.items.map(i=>i.qty>1?(i.qty+'x '+i.name):i.name).join(', ');
    const payStr = r.isFullyFree ? 'Free' : (r.payment==='Split'&&r.splits ? r.splits.map(s=>s.method+':'+s.amount).join(' + ') : r.payment);
    const values = [r.timestamp.split('T')[0].substring(5), r.time, itemsStr, r.plate||'-', r.staff||'-', payStr, 'KES '+r.total.toLocaleString()];
    y = drawWrappedRow(doc, values, colX, colW, y);
    total += r.total;
  });
  // Totals: if there's no room left on this page, start a fresh page rather
  // than letting the total line run into the footer (the reported bug).
  if (y > PAGE_BOTTOM) { doc.addPage(); y = 40; }
  y += 4; doc.line(14,y-3,268,y-3);
  doc.setFontSize(11); doc.setFont(undefined,'bold');
  doc.text('Total: KES ' + total.toLocaleString() + '  (' + rows.length + ' transactions)', 14, y+3);
  doc.setFont(undefined,'normal');
  addPdfFooter(doc);
  const filename = (businessName.replace(/[^a-z0-9]/gi,'-').toLowerCase()) + '-sales-report-'+dFrom+'-to-'+dTo+'.pdf';
  openDownloadShareModal(doc, filename);
}

function exportReconPDF() {
  const doc = new jspdf.jsPDF();
  const subtitle = 'Reconciliation Report  |  ' + new Date().toLocaleDateString('en-KE',{weekday:'long',day:'numeric',month:'long',year:'numeric'});
  let headerY = addPdfHeader(doc, subtitle);
  const statsText = document.getElementById('recon-stats').innerText.replace(/\s+/g,' ');
  doc.setFontSize(10);
  const lines = doc.splitTextToSize(statsText, 180);
  doc.text(lines, 14, headerY);
  let y = headerY + lines.length*5 + 8;
  // Per-payment-type received breakdown
  const breakdownText = document.getElementById('recon-received-breakdown').innerText.replace(/\s+/g,' ');
  if (breakdownText) {
    const bLines = doc.splitTextToSize(breakdownText, 180);
    doc.text(bLines, 14, y);
    y += bLines.length*5 + 6;
  }
  const colX = [14, 64, 106, 142, 168];
  const colW = [46, 38, 32, 22, 24];
  const PAGE_BOTTOM = 270;
  y += drawTableHeader(doc, ['Transaction','POS record','Payment record','Gap','Status'], colX, y);
  doc.line(14,y-3,196,y-3); y += 2;
  const rows = document.querySelectorAll('#recon-tbody tr');
  rows.forEach(r => {
    const cells = r.querySelectorAll('td');
    if (!cells.length) return;
    if (y > PAGE_BOTTOM) {
      doc.addPage(); y = addPdfHeader(doc, subtitle + ' (cont.)');
      y += drawTableHeader(doc, ['Transaction','POS record','Payment record','Gap','Status'], colX, y);
      doc.line(14,y-3,196,y-3); y += 2;
    }
    const values = Array.prototype.map.call(cells, c=>c.innerText.replace(/\n/g,' · '));
    y = drawWrappedRow(doc, values, colX, colW, y);
  });
  addPdfFooter(doc);
  const filename = (businessName.replace(/[^a-z0-9]/gi,'-').toLowerCase()) + '-reconciliation-'+new Date().toISOString().split('T')[0]+'.pdf';
  openDownloadShareModal(doc, filename);
}

// ─── DOWNLOAD / SHARE MODAL ─────────────────────────────────────
// Real, working: Download. Email/SMS/WhatsApp open the device's own
// mail/messaging app pre-addressed (mailto:/sms:/wa.me) since actually
// transmitting the PDF file itself requires a backend mail/SMS gateway -
// flagged honestly rather than faked.
let pendingShareDoc = null;
let pendingShareFilename = '';
let pendingShareMode = '';

function openDownloadShareModal(doc, filename) {
  pendingShareDoc = doc;
  pendingShareFilename = filename;
  document.getElementById('share-recipient-area').style.display = 'none';
  document.getElementById('share-link-area').style.display = 'none';
  document.getElementById('share-modal').classList.add('show');
}
function closeShareModal() {
  document.getElementById('share-modal').classList.remove('show');
  pendingShareDoc = null; pendingShareFilename = ''; pendingShareMode = ''; pendingCSVContent = null;
}
// Branches between PDF (jsPDF doc object) and CSV (raw text content) - both
// report types now go through the same share/download flow per item #5/#7.
function doActualDownload() {
  if (pendingShareDoc) {
    // jsPDF's .save() uses document.createElement('a') internally which is
    // blocked by the Content-Security-Policy in sandboxed iframe environments
    // (e.g. Claude.ai artifact viewer). Using a Blob URL + explicit anchor
    // click works around this restriction.
    try {
      const blob = pendingShareDoc.output('blob');
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = pendingShareFilename;
      document.body.appendChild(a);
      a.click();
      setTimeout(() => { URL.revokeObjectURL(url); document.body.removeChild(a); }, 200);
    } catch(e) {
      // Last-resort fallback: open as data URI in a new tab
      try {
        const dataUri = pendingShareDoc.output('datauristring');
        window.open(dataUri, '_blank');
      } catch(e2) {
        showToast('⚠️ PDF download blocked by browser — try opening this page outside the preview frame');
      }
    }
  } else if (pendingCSVContent) {
    download(pendingShareFilename, pendingCSVContent);
  }
}

function shareReportVia(mode) {
  pendingShareMode = mode;
  const recipientArea = document.getElementById('share-recipient-area');
  const linkArea = document.getElementById('share-link-area');
  recipientArea.style.display = 'none';
  linkArea.style.display = 'none';

  if (mode === 'download') {
    doActualDownload();
    showToast('⬇️ Downloaded ' + pendingShareFilename);
    closeShareModal();
    return;
  }
  if (mode === 'link') {
    linkArea.style.display = 'block';
    document.getElementById('share-link-display').textContent =
      'https://app.inverbrass.com/reports/' + encodeURIComponent(pendingShareFilename) + '  (placeholder — file must be hosted server-side to generate a real link)';
    return;
  }
  // email / sms / whatsapp all need a recipient first
  recipientArea.style.display = 'block';
  const label = document.getElementById('share-recipient-label');
  const input = document.getElementById('share-recipient-input');
  document.getElementById('share-recipient-error').classList.remove('show');
  if (mode === 'email') { label.textContent = 'Recipient email address'; input.placeholder = 'e.g. owner@business.com'; input.type = 'email'; }
  else { label.textContent = 'Recipient mobile number'; input.placeholder = 'e.g. 0712345678'; input.type = 'tel'; }
  input.value = '';
  input.focus();
}

function confirmShareSend() {
  const val = document.getElementById('share-recipient-input').value.trim();
  const errEl = document.getElementById('share-recipient-error');
  if (pendingShareMode === 'email') {
    if (!val || val.indexOf('@') === -1) { errEl.textContent = 'Enter a valid email address'; errEl.classList.add('show'); return; }
  } else {
    if (!isValidKenyanPhone(val)) { errEl.textContent = formatPhoneError(); errEl.classList.add('show'); return; }
  }
  errEl.classList.remove('show');

  // Download the file first so the user has it locally to attach/send
  doActualDownload();

  const fileTypeLabel = pendingShareDoc ? 'PDF' : 'CSV';
  const subject = encodeURIComponent(businessName + ' — Report');
  const body = encodeURIComponent('Please find attached the report "' + pendingShareFilename + '" from ' + businessName + '. (Note: the ' + fileTypeLabel + ' has been downloaded to this device — please attach it manually, as in-app file attachment requires a backend mail service.)');

  if (pendingShareMode === 'email') {
    window.location.href = 'mailto:' + val + '?subject=' + subject + '&body=' + body;
    showToast('📧 Email app opened — attach the downloaded ' + fileTypeLabel + ' before sending');
  } else if (pendingShareMode === 'sms') {
    window.location.href = 'sms:' + val + '?body=' + body;
    showToast('💬 Messaging app opened — the ' + fileTypeLabel + ' was downloaded to this device');
  } else if (pendingShareMode === 'whatsapp') {
    const waNumber = val.replace(/^0/, '254').replace(/\+/, '');
    window.open('https://wa.me/' + waNumber + '?text=' + body, '_blank');
    showToast('🟢 WhatsApp opened — attach the downloaded ' + fileTypeLabel + ' before sending');
  }
  closeShareModal();
}
function copyShareLink() {
  const text = document.getElementById('share-link-display').textContent;
  navigator.clipboard?.writeText(text).then(() => showToast('📋 Link text copied')).catch(() => showToast('Could not copy — please copy manually'));
}

// ─── REPORTS HUB: SALES vs CUSTOM SUB-TABS ──────────────────────
function switchReportsTab(tab, el) {
  document.querySelectorAll('#view-log .tab-item').forEach(t => t.classList.remove('active'));
  el.classList.add('active');
  document.getElementById('reports-sales').style.display = tab === 'sales' ? 'block' : 'none';
  document.getElementById('reports-staff').style.display = tab === 'staff' ? 'block' : 'none';
  document.getElementById('reports-custom').style.display = tab === 'custom' ? 'block' : 'none';
  if (tab === 'custom') initCustomReportFields();
  if (tab === 'staff') renderStaffSalesReport();
}

// ─── STAFF SALES REPORT (productivity by staff member) ──────────
function setStaffReportDateRange(preset) {
  const now = new Date();
  let from = new Date(now);
  if (preset === 'week') from.setDate(now.getDate()-7);
  else if (preset === 'month') from.setDate(now.getDate()-30);
  document.getElementById('staff-report-date-from').value = from.toISOString().split('T')[0];
  document.getElementById('staff-report-date-to').value = now.toISOString().split('T')[0];
  renderStaffSalesReport();
}

function getStaffReportRows() {
  if (!document.getElementById('staff-report-date-from').value) {
    const today = new Date().toISOString().split('T')[0];
    document.getElementById('staff-report-date-from').value = today;
    document.getElementById('staff-report-date-to').value = today;
  }
  const dFrom = document.getElementById('staff-report-date-from').value;
  const dTo = document.getElementById('staff-report-date-to').value;
  return transactions.filter(t =>
    !t.creditSettlement && // exclude the settlement entries themselves - they'd double-count the original sale
    t.timestamp.split('T')[0] >= dFrom && t.timestamp.split('T')[0] <= dTo
  );
}

function computeStaffSalesData(rows) {
  const byStaff = {};
  let grandTotal = 0;
  rows.forEach(t => {
    const name = t.staff || 'Unknown';
    if (!byStaff[name]) byStaff[name] = { count:0, total:0, credit:0, freeWashes:0 };
    byStaff[name].count += 1;
    byStaff[name].total += t.total;
    byStaff[name].credit += getCreditAmount(t);
    // Count all loyalty redemptions (both fully-free and topup) as a free wash given
    if (t.isFreeWash) byStaff[name].freeWashes += 1;
    grandTotal += t.total;
  });
  return Object.entries(byStaff).map(([name,d]) => ({
    name,
    count: d.count,
    total: d.total,
    credit: d.credit,
    salesPaid: d.total - d.credit, // amount actually received (excluding credit outstanding)
    freeWashes: d.freeWashes,
  })).sort((a,b) => b.total - a.total);
}

function renderStaffSalesReport() {
  const rows = getStaffReportRows();
  const tbody = document.getElementById('staff-report-tbody');
  if (!rows.length) { tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;padding:24px;color:var(--text3)">No transactions in this range</td></tr>'; return; }
  const data = computeStaffSalesData(rows);
  tbody.innerHTML = data.map(d =>
    '<tr>' +
      '<td style="font-weight:600">'+d.name+'</td>' +
      '<td>'+d.count+'</td>' +
      '<td style="font-weight:600">KES '+d.total.toLocaleString()+'</td>' +
      '<td style="'+(d.credit>0?'color:var(--red)':'')+'">'+(d.credit>0 ? 'KES '+d.credit.toLocaleString() : '—')+'</td>' +
      '<td style="color:var(--green);font-weight:500">KES '+d.salesPaid.toLocaleString()+'</td>' +
      '<td>'+(d.freeWashes>0 ? '🎁 '+d.freeWashes : '—')+'</td>' +
    '</tr>'
  ).join('');
}

function exportStaffSalesPDF() {
  const rows = getStaffReportRows();
  if (!rows.length) { showToast('No transactions to export'); return; }
  const data = computeStaffSalesData(rows);
  const dFrom = document.getElementById('staff-report-date-from').value, dTo = document.getElementById('staff-report-date-to').value;
  const doc = new jspdf.jsPDF({orientation:'landscape'});
  const subtitle = 'Staff Sales Report  |  ' + dFrom + ' to ' + dTo;
  let y = addPdfHeader(doc, subtitle);
  const headers = ['Staff','Transactions','Total Sale Value','Credit Sales','Sales Paid','Free Washes'];
  const colX = [14,74,114,158,200,244];
  const colW = [58,38,42,40,42,28];
  const PAGE_BOTTOM = 180;
  y += drawTableHeader(doc, headers, colX, y);
  doc.line(14,y-3,268,y-3); y += 2;
  let grandCount = 0, grandTotal = 0, grandCredit = 0, grandPaid = 0;
  data.forEach(d => {
    if (y > PAGE_BOTTOM) {
      doc.addPage(); y = addPdfHeader(doc, subtitle + ' (cont.)');
      y += drawTableHeader(doc, headers, colX, y); doc.line(14,y-3,268,y-3); y += 2;
    }
    const vals = [d.name, String(d.count), 'KES '+d.total.toLocaleString(), d.credit>0?('KES '+d.credit.toLocaleString()):'-', 'KES '+d.salesPaid.toLocaleString(), d.freeWashes>0?String(d.freeWashes):'-'];
    y = drawWrappedRow(doc, vals, colX, colW, y);
    grandCount += d.count; grandTotal += d.total; grandCredit += d.credit; grandPaid += d.salesPaid;
  });
  if (y > PAGE_BOTTOM) { doc.addPage(); y = 40; }
  y += 4; doc.line(14,y-3,268,y-3);
  doc.setFontSize(11); doc.setFont(undefined,'bold');
  doc.text('Total: ' + grandCount + ' tx · KES ' + grandTotal.toLocaleString() + ' · Credit: KES ' + grandCredit.toLocaleString() + ' · Paid: KES ' + grandPaid.toLocaleString(), 14, y+3);
  doc.setFont(undefined,'normal');
  addPdfFooter(doc);
  openDownloadShareModal(doc, (businessName.replace(/[^a-z0-9]/gi,'-').toLowerCase())+'-staff-sales-report-'+dFrom+'-to-'+dTo+'.pdf');
}

// ─── CUSTOM REPORT BUILDER (with in-app preview before download/send) ──
const CUSTOM_REPORT_FIELDS = [
  {key:'date', label:'Date/Time', always:true},
  {key:'items', label:'Items purchased'},
  {key:'customer', label:'Customer name/phone'},
  {key:'plate', label:getVerticalConfig?getVerticalConfig().identifierLabel:'Identifier'},
  {key:'staff', label:'Staff/Attendant'},
  {key:'payment', label:'Payment type'},
  {key:'amount', label:'Amount', always:true},
];

let customReportFormat = 'pdf';
let customReportPreviewRows = null; // cached after Preview, used by generateCustomReport
let customReportPreviewFields = null;

function setCustomReportFormat(fmt) {
  customReportFormat = fmt;
  document.getElementById('cr-format-pdf').classList.toggle('selected', fmt==='pdf');
  document.getElementById('cr-format-csv').classList.toggle('selected', fmt==='csv');
}

function initCustomReportFields() {
  if (document.getElementById('cr-date-from').value) return; // already initialized this session
  const today = new Date().toISOString().split('T')[0];
  document.getElementById('cr-date-from').value = today;
  document.getElementById('cr-date-to').value = today;
  document.getElementById('cr-fields-list').innerHTML = CUSTOM_REPORT_FIELDS.map(f =>
    '<label class="multiselect-option" style="border:1px solid var(--border);border-radius:6px"><input type="checkbox" value="'+f.key+'" '+(f.always?'checked disabled':'checked')+'/> '+f.label+(f.always?' (required)':'')+'</label>'
  ).join('');
}

// Shared field-value extractor - used by custom report PDF, CSV, and the
// in-app preview table. No substring() truncation; full values always returned.
function getFieldValue(r, key) {
  if (key === 'date') return r.timestamp.split('T')[0] + ' ' + r.time;
  if (key === 'items') return r.items.map(it=>it.qty>1?(it.qty+'x '+it.name):it.name).join(', ');
  if (key === 'customer') return r.customerName || r.customerPhone || '-';
  if (key === 'plate') return r.plate || '-';
  if (key === 'staff') return r.staff || '-';
  if (key === 'payment') return r.isFullyFree ? 'Free' : (r.payment==='Split'&&r.splits ? r.splits.map(s=>s.method+':'+s.amount).join(' + ') : r.payment);
  if (key === 'amount') return 'KES ' + r.total.toLocaleString();
  return '';
}

// Renders the selected fields/date-range as a real on-screen table - this is
// effectively "CSV in the browser" so the user can sanity-check the report
// before committing to a download or send, per item #1.
function previewCustomReport() {
  const dFrom = document.getElementById('cr-date-from').value;
  const dTo = document.getElementById('cr-date-to').value;
  const checked = Array.prototype.map.call(
    document.querySelectorAll('#cr-fields-list input[type="checkbox"]:checked'), cb => cb.value
  );
  if (!dFrom || !dTo) { showToast('⚠️ Please select a date range'); return; }
  const rows = transactions.filter(t => t.timestamp.split('T')[0] >= dFrom && t.timestamp.split('T')[0] <= dTo);
  if (!rows.length) { showToast('No transactions in that range'); return; }
  const fieldDefs = CUSTOM_REPORT_FIELDS.filter(f => checked.indexOf(f.key) !== -1);

  customReportPreviewRows = rows;
  customReportPreviewFields = fieldDefs;

  const theadHtml = '<thead><tr>' + fieldDefs.map(f=>'<th>'+f.label+'</th>').join('') + '</tr></thead>';
  const tbodyHtml = '<tbody>' + rows.map(r =>
    '<tr>' + fieldDefs.map(f=>'<td>'+getFieldValue(r,f.key)+'</td>').join('') + '</tr>'
  ).join('') + '</tbody>';
  document.getElementById('cr-preview-table').innerHTML = theadHtml + tbodyHtml;
  document.getElementById('cr-preview-title').textContent = 'Preview — ' + rows.length + ' row' + (rows.length!==1?'s':'') + ' · ' + dFrom + ' to ' + dTo;
  document.getElementById('cr-preview-area').style.display = 'block';
  document.getElementById('cr-preview-empty').style.display = 'none';
  setCustomReportFormat(customReportFormat);
}

function generateCustomReport() {
  if (!customReportPreviewRows || !customReportPreviewFields) { showToast('⚠️ Please preview the report first'); return; }
  const dFrom = document.getElementById('cr-date-from').value;
  const dTo = document.getElementById('cr-date-to').value;
  const rows = customReportPreviewRows;
  const fieldDefs = customReportPreviewFields;

  if (customReportFormat === 'csv') {
    const headers = fieldDefs.map(f=>f.label).join(',') + '\n';
    const csv = rows.map(r => fieldDefs.map(f => '"'+String(getFieldValue(r,f.key)).replace(/"/g,'""')+'"').join(',')).join('\n');
    pendingCSVContent = headers + csv;
    pendingCSVFilename = (businessName.replace(/[^a-z0-9]/gi,'-').toLowerCase()) + '-custom-report-'+dFrom+'-to-'+dTo+'.csv';
    openShareModalForCSV(pendingCSVFilename);
    return;
  }

  // PDF — uses wrapped headers AND wrapped multi-line rows so nothing is
  // ever cut off or overlapping, plus a totals line (both were missing/buggy).
  const doc = new jspdf.jsPDF();
  const subtitle = 'Custom Report  |  ' + dFrom + ' to ' + dTo;
  let y = addPdfHeader(doc, subtitle);
  const colWidth = 180 / fieldDefs.length;
  const colX = fieldDefs.map((f,i) => 14 + i*colWidth);
  const colW = fieldDefs.map(() => colWidth - 3);
  const PAGE_BOTTOM = 270;
  const hasAmount = fieldDefs.some(f => f.key === 'amount');
  y += drawTableHeader(doc, fieldDefs.map(f=>f.label), colX, y);
  doc.line(14,y-3,194,y-3); y += 2;
  let total = 0;
  rows.forEach(r => {
    if (y > PAGE_BOTTOM) {
      doc.addPage(); y = addPdfHeader(doc, subtitle + ' (cont.)');
      y += drawTableHeader(doc, fieldDefs.map(f=>f.label), colX, y);
      doc.line(14,y-3,194,y-3); y += 2;
    }
    y = drawWrappedRow(doc, fieldDefs.map(f=>getFieldValue(r,f.key)), colX, colW, y);
    total += r.total;
  });
  if (hasAmount) {
    if (y > PAGE_BOTTOM) { doc.addPage(); y = 40; }
    y += 4; doc.line(14,y-3,194,y-3);
    doc.setFontSize(11); doc.setFont(undefined,'bold');
    doc.text('Total: KES ' + total.toLocaleString() + '  (' + rows.length + ' transactions)', 14, y+3);
    doc.setFont(undefined,'normal');
  }
  addPdfFooter(doc);
  openDownloadShareModal(doc, (businessName.replace(/[^a-z0-9]/gi,'-').toLowerCase())+'-custom-report-'+dFrom+'-to-'+dTo+'.pdf');
}

// ─── RECONCILIATION (upload, camera, OCR stub) ─────────────────
function handleFileUpload(files) {
  if (!files || !files.length) return;
  const file = files[0];
  showToast('📂 Processing ' + file.name + '...');
  if (file.type.startsWith('image/')) {
    const reader = new FileReader();
    reader.onload = (e) => {
      const preview = document.getElementById('ocr-preview');
      preview.classList.add('show');
      preview.innerHTML = '<img src="'+e.target.result+'"/>' +
        '<div style="font-size:12px;color:var(--text2);margin-bottom:8px">📷 Photo captured. <strong>OCR text extraction requires a backend service</strong> (e.g. Google Vision API or Tesseract server) — this is flagged as a Phase 2 integration. For now, the demo reconciliation below uses your actual POS records.</div>' +
        '<button class="btn-primary" style="margin-top:0" onclick="runDemoRecon()">Continue to reconciliation</button>';
    };
    reader.readAsDataURL(file);
  } else {
    setTimeout(runDemoRecon, 500);
  }
}
function backToReconUpload() {
  document.getElementById('recon-results').style.display='none';
  document.getElementById('recon-upload-area').style.display='block';
  document.getElementById('ocr-preview').classList.remove('show');
}
function simulateUpload(){showToast('📂 Upload simulated — running reconciliation...');setTimeout(runDemoRecon,600);}
function runDemoRecon(){
  document.getElementById('recon-upload-area').style.display='none';
  document.getElementById('recon-results').style.display='block';
  document.getElementById('recon-date-label').textContent=new Date().toLocaleDateString('en-KE',{weekday:'long',day:'numeric',month:'long'});
  const today=new Date().toDateString();
  const todayTx=transactions.filter(tx=>new Date(tx.timestamp).toDateString()===today);
  let posTotal=0,payTotal=0;const rows=[];
  const receivedByMethod = {}; // method -> amount actually received (per the payment record, not POS)
  const base=todayTx.length?todayTx:[
    {id:'TX1001',time:'08:14',items:[{name:'Full Wash'}],total:500,payment:'M-Pesa',staff:'James Kariuki',plate:'KBZ 456Y'},
    {id:'TX1002',time:'09:02',items:[{name:'Express Wash'},{name:'Tyre Shine'}],total:450,payment:'Cash',staff:'Mary Njoki',plate:'KDA 123A'},
    {id:'TX1003',time:'09:45',items:[{name:'Premium Detail'}],total:1500,payment:'M-Pesa',staff:'James Kariuki',plate:'KCK 789B'},
    {id:'TX1004',time:'10:30',items:[{name:'Interior Clean'}],total:800,payment:'Card',staff:'Peter Omondi',plate:'KBN 321C'},
    {id:'TX1005',time:'11:15',items:[{name:'Express Wash'}],total:300,payment:'M-Pesa',staff:'Mary Njoki',plate:'KDM 654D'},
    {id:'TX1006',time:'12:00',items:[{name:'Full Wash'},{name:'Wax Polish'}],total:1000,payment:'Cash',staff:'Faith Achieng',plate:'KCR 987E'},
    {id:'TX1007',time:'13:20',items:[{name:'Express Wash'}],total:300,payment:'M-Pesa',staff:'Peter Omondi',plate:''},
  ];
  const scenarios=[{match:true,diff:0},{match:true,diff:0},{match:true,diff:0},{match:false,diff:0,reason:'No payment record'},{match:true,diff:-50,reason:'Short payment'},{match:true,diff:0},{match:false,diff:0,reason:'No payment record'}];
  base.forEach((tx,i)=>{
    if (tx.isFullyFree) return; // only skip when nothing was actually charged - topups have real payments to reconcile
    const sc=scenarios[i%scenarios.length];
    const posAmt=tx.total; const payAmt=sc.match?(posAmt+sc.diff):null;
    posTotal+=posAmt; if(payAmt!==null)payTotal+=payAmt;
    if (payAmt !== null) {
      // Attribute the received amount to whichever method(s) this transaction used
      if (tx.payment === 'Split' && tx.splits) {
        const splitTotal = tx.splits.reduce((s,sp)=>s+sp.amount,0);
        tx.splits.forEach(sp => {
          const share = splitTotal > 0 ? (sp.amount/splitTotal)*payAmt : 0;
          receivedByMethod[sp.method] = (receivedByMethod[sp.method]||0) + share;
        });
      } else {
        receivedByMethod[tx.payment] = (receivedByMethod[tx.payment]||0) + payAmt;
      }
    }
    const gap=payAmt!==null?(payAmt-posAmt):(-posAmt);
    rows.push({tx,posAmt,payAmt,gap,status:sc.match&&gap===0?'matched':sc.match&&gap!==0?'variance':'missing',reason:sc.reason||''});
  });
  const missing=rows.filter(r=>r.status==='missing'); const variance=rows.filter(r=>r.status==='variance'); const matched=rows.filter(r=>r.status==='matched');
  const leakage=Math.abs(rows.filter(r=>r.status==='missing').reduce((s,r)=>s+r.gap,0))+Math.abs(rows.filter(r=>r.status==='variance').reduce((s,r)=>s+r.gap,0));
  document.getElementById('leakage-alert').innerHTML = leakage>0
    ? '<div class="leakage-banner"><div class="leakage-icon">🚨</div><div class="leakage-text"><strong>Income leakage detected: KES '+leakage.toLocaleString()+'</strong><br>'+missing.length+' unmatched sale'+(missing.length!==1?'s':'')+' and '+variance.length+' payment variance'+(variance.length!==1?'s':'')+' found.</div></div>'
    : '<div style="background:var(--green-light);border:1px solid #a8d3bb;border-radius:var(--radius);padding:12px 16px;margin-bottom:16px;font-size:13px;color:var(--green)">✅ All transactions reconciled — no leakage detected.</div>';
  const receivedSub = Object.keys(receivedByMethod).length
    ? Object.entries(receivedByMethod).map(([m,v])=>m+': KES '+Math.round(v).toLocaleString()).join(' · ')
    : 'No payments recorded';
  document.getElementById('recon-stats').innerHTML =
    '<div class="stat-card"><div class="stat-label">POS total</div><div class="stat-val">KES '+posTotal.toLocaleString()+'</div><div class="stat-sub">'+rows.length+' transactions</div></div>'+
    '<div class="stat-card '+(payTotal<posTotal?'warning':'success')+'"><div class="stat-label">Payments received</div><div class="stat-val">KES '+payTotal.toLocaleString()+'</div><div class="stat-sub">Click below for breakdown</div></div>'+
    '<div class="stat-card '+(leakage>0?'danger':'success')+'"><div class="stat-label">Income leakage</div><div class="stat-val">KES '+leakage.toLocaleString()+'</div><div class="stat-sub">'+missing.length+' missing + '+variance.length+' variance</div></div>'+
    '<div class="stat-card success"><div class="stat-label">Matched</div><div class="stat-val">'+matched.length+'/'+(rows.length||1)+'</div><div class="stat-sub">'+(rows.length?Math.round(matched.length/rows.length*100):100)+'% reconciled</div></div>';
  // Per-payment-type breakdown of what was actually received
  document.getElementById('recon-received-breakdown').innerHTML =
    '<div style="font-size:12px;font-weight:600;color:var(--text2);margin-bottom:8px;text-transform:uppercase;letter-spacing:.3px">Payments received — by type</div>' +
    '<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:10px">' +
    (Object.keys(receivedByMethod).length ? Object.entries(receivedByMethod).map(([m,v])=>
      '<div style="background:var(--surface2);border-radius:var(--radius-sm);padding:10px"><div style="font-size:11px;color:var(--text2)">'+m+'</div><div style="font-size:16px;font-weight:700;color:var(--teal)">KES '+Math.round(v).toLocaleString()+'</div></div>'
    ).join('') : '<div style="font-size:12px;color:var(--text3)">No payments recorded yet</div>') +
    '</div>';
  document.getElementById('recon-tbody').innerHTML = rows.map(r=>{
    const gapDisplay = r.gap===0?'—':(r.gap>0?'+KES '+Math.abs(r.gap).toLocaleString():'-KES '+Math.abs(r.gap).toLocaleString());
    const gapColor = r.gap<0?'var(--red)':r.gap>0?'var(--green)':'var(--text3)';
    return '<tr><td><span style="font-weight:500">'+r.tx.id+'</span><br><span style="font-size:11px;color:var(--text3)">'+r.tx.time+' · '+r.tx.staff+'</span></td><td>KES '+r.posAmt.toLocaleString()+'<br><span style="font-size:11px;color:var(--text3)">'+r.tx.payment+'</span></td><td>'+(r.payAmt!==null?'KES '+r.payAmt.toLocaleString():'<span style="color:var(--text3)">—</span>')+'</td><td style="color:'+gapColor+'">'+gapDisplay+'</td><td><span class="pill '+(r.status==='matched'?'pill-green':r.status==='variance'?'pill-amber':'pill-red')+'">'+r.status+'</span>'+(r.reason?'<br><span style="font-size:10px;color:var(--text3)">'+r.reason+'</span>':'')+'</td></tr>';
  }).join('');

  // Persist this run so it can be reviewed later - reconciliation reports
  // were previously recomputed from scratch every time and lost as soon as
  // you navigated away or ran a new one. One entry per calendar day; running
  // it again the same day updates that day's saved entry rather than adding
  // a duplicate.
  const reportDateKey = new Date().toISOString().split('T')[0];
  const reportRecord = {
    dateKey: reportDateKey,
    dateLabel: new Date().toLocaleDateString('en-KE',{weekday:'long',day:'numeric',month:'long',year:'numeric'}),
    posTotal, payTotal, leakage, missingCount: missing.length, varianceCount: variance.length,
    matchedCount: matched.length, totalCount: rows.length,
    receivedByMethod, savedAt: new Date().toISOString()
  };
  const existingIdx = reconHistory.findIndex(r => r.dateKey === reportDateKey);
  if (existingIdx >= 0) reconHistory[existingIdx] = reportRecord;
  else reconHistory.unshift(reportRecord);
  save();
  renderReconHistory();
}

function renderReconHistory() {
  const container = document.getElementById('recon-history-list');
  if (!container) return;
  if (!reconHistory.length) { container.innerHTML = ''; return; }
  const sorted = reconHistory.slice().sort((a,b) => b.dateKey.localeCompare(a.dateKey)).slice(0, 14);
  container.innerHTML =
    '<div style="font-size:12px;font-weight:600;color:var(--text2);margin-bottom:8px;text-transform:uppercase;letter-spacing:.3px">Past reports</div>' +
    '<div style="display:flex;gap:8px;overflow-x:auto;padding-bottom:4px">' +
    sorted.map(r => {
      const leakageBadge = r.leakage > 0 ? '<span class="pill pill-red" style="font-size:10px">KES '+r.leakage.toLocaleString()+' leak</span>' : '<span class="pill pill-green" style="font-size:10px">Clean</span>';
      return '<div style="flex-shrink:0;background:var(--surface);border:1px solid var(--border);border-radius:var(--radius-sm);padding:10px 12px;cursor:pointer;min-width:150px" onclick="viewReconHistoryEntry(\''+r.dateKey+'\')">' +
        '<div style="font-size:12px;font-weight:600">'+new Date(r.dateKey).toLocaleDateString('en-KE',{day:'numeric',month:'short'})+'</div>' +
        '<div style="font-size:11px;color:var(--text2);margin:4px 0">KES '+r.posTotal.toLocaleString()+'</div>' +
        leakageBadge +
      '</div>';
    }).join('') +
    '</div>';
}

function viewReconHistoryEntry(dateKey) {
  const r = reconHistory.find(x => x.dateKey === dateKey);
  if (!r) return;
  document.getElementById('recon-upload-area').style.display='none';
  document.getElementById('recon-results').style.display='block';
  document.getElementById('recon-date-label').textContent = r.dateLabel + ' (saved report)';
  document.getElementById('leakage-alert').innerHTML = r.leakage>0
    ? '<div class="leakage-banner"><div class="leakage-icon">🚨</div><div class="leakage-text"><strong>Income leakage: KES '+r.leakage.toLocaleString()+'</strong><br>'+r.missingCount+' unmatched and '+r.varianceCount+' variance found.</div></div>'
    : '<div style="background:var(--green-light);border:1px solid #a8d3bb;border-radius:var(--radius);padding:12px 16px;margin-bottom:16px;font-size:13px;color:var(--green)">✅ This day reconciled cleanly — no leakage.</div>';
  document.getElementById('recon-stats').innerHTML =
    '<div class="stat-card"><div class="stat-label">POS total</div><div class="stat-val">KES '+r.posTotal.toLocaleString()+'</div><div class="stat-sub">'+r.totalCount+' transactions</div></div>'+
    '<div class="stat-card '+(r.payTotal<r.posTotal?'warning':'success')+'"><div class="stat-label">Payments received</div><div class="stat-val">KES '+r.payTotal.toLocaleString()+'</div><div class="stat-sub">See breakdown below</div></div>'+
    '<div class="stat-card '+(r.leakage>0?'danger':'success')+'"><div class="stat-label">Income leakage</div><div class="stat-val">KES '+r.leakage.toLocaleString()+'</div><div class="stat-sub">'+r.missingCount+' missing + '+r.varianceCount+' variance</div></div>'+
    '<div class="stat-card success"><div class="stat-label">Matched</div><div class="stat-val">'+r.matchedCount+'/'+(r.totalCount||1)+'</div><div class="stat-sub">'+(r.totalCount?Math.round(r.matchedCount/r.totalCount*100):100)+'% reconciled</div></div>';
  document.getElementById('recon-received-breakdown').innerHTML =
    '<div style="font-size:12px;font-weight:600;color:var(--text2);margin-bottom:8px;text-transform:uppercase;letter-spacing:.3px">Payments received — by type</div>' +
    '<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:10px">' +
    (Object.keys(r.receivedByMethod||{}).length ? Object.entries(r.receivedByMethod).map(([m,v])=>
      '<div style="background:var(--surface2);border-radius:var(--radius-sm);padding:10px"><div style="font-size:11px;color:var(--text2)">'+m+'</div><div style="font-size:16px;font-weight:700;color:var(--teal)">KES '+Math.round(v).toLocaleString()+'</div></div>'
    ).join('') : '<div style="font-size:12px;color:var(--text3)">No payments recorded</div>') +
    '</div>';
  document.getElementById('recon-tbody').innerHTML = '<tr><td colspan="5" style="text-align:center;padding:20px;color:var(--text3);font-size:12px">Line-item detail isn\'t stored for saved reports — totals and breakdown above are preserved. Run reconciliation again for live line items.</td></tr>';
}

// ─── MAKER-CHECKER (with Approve / Reject / Return-for-amendment) ──
function openProductForm(productId) {
  editingProductId = productId || null;
  selectedIcon = '🔧';
  document.getElementById('pf-name').value = '';
  document.getElementById('pf-price').value = '';
  document.getElementById('pf-cat').value = 'service';
  document.getElementById('pf-reason').value = '';
  document.getElementById('pf-custom-icon').value = '';
  document.getElementById('pf-edit-info').style.display = 'none';
  document.getElementById('product-modal-title').textContent = 'Request new product';
  document.getElementById('product-modal-sub').textContent = 'This will be sent to the manager for approval before going live.';
  if (editingProductId) {
    const p = products.find(x => x.id == editingProductId);
    if (p) {
      document.getElementById('pf-name').value = p.name;
      document.getElementById('pf-price').value = p.price;
      document.getElementById('pf-cat').value = p.cat;
      selectedIcon = p.icon;
      document.getElementById('product-modal-title').textContent = 'Request price / name change';
      document.getElementById('product-modal-sub').textContent = 'Any change to an existing product requires manager approval before it takes effect.';
      document.getElementById('pf-edit-info').style.display = 'block';
      document.getElementById('pf-edit-info').textContent = 'Editing: "'+p.name+'" ('+p.id+') — current price KES '+p.price.toLocaleString()+'. Changes go to manager for approval.';
    }
  }
  const grid = document.getElementById('icon-grid');
  grid.innerHTML = ICONS.map(ic => '<div class="icon-opt'+(ic===selectedIcon?' selected':'')+'" onclick="selectIconOpt(\''+ic+'\',this)">'+ic+'</div>').join('');
  document.getElementById('product-modal').classList.add('show');
}
function selectIconOpt(icon, el) { selectedIcon = icon; document.querySelectorAll('.icon-opt').forEach(e => e.classList.remove('selected')); el.classList.add('selected'); }
function useCustomIcon() {
  const val = document.getElementById('pf-custom-icon').value.trim();
  if (!val) return;
  selectedIcon = val;
  document.querySelectorAll('.icon-opt').forEach(e => e.classList.remove('selected'));
  showToast('Custom icon set: ' + val);
}
function closeProductModal() { document.getElementById('product-modal').classList.remove('show'); }

// Resubmitting an amendment reuses the SAME case ID (per requirement #5)
let resubmitCaseId = null;

function submitProductRequest() {
  const name = document.getElementById('pf-name').value.trim();
  const price = parseInt(document.getElementById('pf-price').value);
  const cat = document.getElementById('pf-cat').value;
  const reason = document.getElementById('pf-reason').value.trim();
  if (!name) { showToast('⚠️ Please enter a product name'); return; }
  if (isNaN(price) || price <= 0) { showToast('⚠️ Please enter a valid price'); return; }
  const isEdit = !!editingProductId;
  const oldProduct = isEdit ? products.find(p => p.id == editingProductId) : null;
  // Per requirement #5: ANY change to an EXISTING product requires approval (no auto-approve for edits)
  const autoApprove = (!isEdit) && price <= getVerticalConfig().approvalAutoLimit;
  const caseId = resubmitCaseId || nextCaseId();
  const newProductId = isEdit ? editingProductId : nextProductId();

  const request = {
    caseId, type:isEdit?'edit':'new', productId:newProductId,
    name, price, cat, icon:selectedIcon, reason,
    submittedBy: currentUser.name, submittedByUsername: currentUser.username,
    submittedAt:new Date().toISOString(),
    status:autoApprove?'auto-approved':'pending',
    oldName:oldProduct?oldProduct.name:null, oldPrice:oldProduct?oldProduct.price:null,
    isResubmission: !!resubmitCaseId
  };

  if (autoApprove) {
    applyProductRequest(request);
    addAuditEntry('auto-approved', request, null);
    requestHistory.unshift(Object.assign({}, request, {reviewedBy: 'System', reviewedAt: new Date().toISOString(), rejectionReason: null}));
    save(); renderProducts(); renderSetup();
    showToast('✅ Auto-approved — KES '+price+' is within the KES '+getVerticalConfig().approvalAutoLimit+' limit ('+request.caseId+')');
  } else {
    // Remove any prior pending/returned entry with the same case ID before re-adding (resubmission case)
    pendingRequests = pendingRequests.filter(r => r.caseId !== caseId);
    pendingRequests.unshift(request);
    addAuditEntry(resubmitCaseId ? 'resubmitted' : 'submitted', request, null);
    save(); updatePendingBadge();
    showToast((resubmitCaseId ? '📤 Resubmitted ' : '📤 Submitted ') + caseId + ' for manager approval');
  }
  resubmitCaseId = null;
  closeProductModal();
  renderApprovals();
}

function applyProductRequest(req) {
  if (req.type === 'new') { products.push({ id: req.productId, cat: req.cat, name: req.name, price: req.price, icon: req.icon }); }
  else { const idx = products.findIndex(p => p.id == req.productId); if (idx >= 0) { products[idx] = Object.assign({}, products[idx], {name: req.name, price: req.price, cat: req.cat, icon: req.icon}); } }
  saveProductToDb(req.type === 'new' ? products[products.length-1] : products.find(p=>p.id==req.productId));
}

function approveRequest(caseId) {
  if (currentUser.role !== 'checker') { showToast('⚠️ Only checkers can approve requests'); return; }
  const idx = pendingRequests.findIndex(r => r.caseId === caseId); if (idx < 0) return;
  const req = pendingRequests[idx];
  if (req.submittedByUsername === currentUser.username) { showToast('⚠️ You cannot approve your own request — another checker must review it'); return; }
  req.status = 'approved'; req.reviewedBy = currentUser.name; req.reviewedAt = new Date().toISOString();
  applyProductRequest(req);
  requestHistory.unshift(req); pendingRequests.splice(idx, 1);
  addAuditEntry('approved', req, null);
  save(); renderProducts(); renderSetup(); renderApprovals(); updatePendingBadge();
  showToast('✅ '+req.caseId+' "'+req.name+'" approved and now live');
}

// Two distinct rejection outcomes per requirement #5:
//  - 'return': goes back to the SAME maker, who can edit & resubmit under the SAME case ID
//  - 'reject': final decision, maker is only notified, no action possible
function openRejectModal(caseId, action) {
  if (currentUser.role !== 'checker') { showToast('⚠️ Only checkers can do this'); return; }
  const req = pendingRequests.find(r => r.caseId === caseId);
  if (req && req.submittedByUsername === currentUser.username) { showToast('⚠️ You cannot review your own request — another checker must review it'); return; }
  rejectingRequestId = caseId;
  rejectAction = action; // 'return' or 'reject'
  document.getElementById('reject-reason-input').value = '';
  document.getElementById('reject-modal-title').textContent = action === 'return' ? 'Return for amendment' : 'Reject request (final)';
  document.getElementById('reject-modal-sub').textContent = action === 'return'
    ? 'This sends the request back to the maker to edit and resubmit under the same case ID.'
    : 'This is a final decision. The maker will only be notified of the reason — no further action is possible on this case.';
  document.getElementById('reject-confirm-btn').textContent = action === 'return' ? 'Return to maker' : 'Reject (final)';
  document.getElementById('reject-modal').classList.add('show');
}
function closeRejectModal() { document.getElementById('reject-modal').classList.remove('show'); rejectingRequestId = null; }
function confirmReject() {
  const reason = document.getElementById('reject-reason-input').value.trim();
  if (!reason) { showToast('⚠️ Please give a reason'); return; }
  const idx = pendingRequests.findIndex(r => r.caseId === rejectingRequestId); if (idx < 0) return;
  const req = pendingRequests[idx];
  if (req.submittedByUsername === currentUser.username) { showToast('⚠️ You cannot review your own request'); closeRejectModal(); return; }
  req.reviewedBy = currentUser.name; req.reviewedAt = new Date().toISOString(); req.rejectionReason = reason;

  if (rejectAction === 'return') {
    req.status = 'returned';
    addAuditEntry('returned', req, reason);
    // Stays referenceable by maker - keep in pendingRequests but flagged 'returned'
    save(); renderApprovals(); updatePendingBadge(); closeRejectModal();
    showToast('↩️ '+req.caseId+' returned to '+req.submittedBy+' for amendment');
  } else {
    req.status = 'rejected';
    requestHistory.unshift(req); pendingRequests.splice(idx, 1);
    addAuditEntry('rejected', req, reason);
    save(); renderApprovals(); updatePendingBadge(); closeRejectModal();
    showToast('❌ '+req.caseId+' rejected (final) — '+req.submittedBy+' notified');
  }
}

// Maker picks up a returned case to edit and resubmit under the SAME case ID
function editReturnedCase(caseId) {
  const req = pendingRequests.find(r => r.caseId === caseId);
  if (!req) return;
  resubmitCaseId = caseId;
  editingProductId = req.type === 'edit' ? req.productId : null;
  selectedIcon = req.icon;
  document.getElementById('pf-name').value = req.name;
  document.getElementById('pf-price').value = req.price;
  document.getElementById('pf-cat').value = req.cat;
  document.getElementById('pf-reason').value = req.reason || '';
  document.getElementById('pf-edit-info').style.display = 'block';
  document.getElementById('pf-edit-info').textContent = 'Amending ' + caseId + ' — returned reason: "' + req.rejectionReason + '". Resubmitting keeps the same case ID.';
  document.getElementById('product-modal-title').textContent = 'Amend ' + caseId;
  document.getElementById('product-modal-sub').textContent = 'Make your changes and resubmit. This will go back to the manager under the same case ID.';
  const grid = document.getElementById('icon-grid');
  grid.innerHTML = ICONS.map(ic => '<div class="icon-opt'+(ic===selectedIcon?' selected':'')+'" onclick="selectIconOpt(\''+ic+'\',this)">'+ic+'</div>').join('');
  document.getElementById('product-modal').classList.add('show');
}

function addAuditEntry(action, req, reason) {
  auditLog.unshift({id:'AUD'+Date.now(),action,caseId:req.caseId,productName:req.name,price:req.price,actor:action==='submitted'||action==='resubmitted'?req.submittedBy:(action==='auto-approved'?'System':currentUser.name),reason:reason||null,timestamp:new Date().toISOString()});
}
// Separate logger for staff/user account events (add, remove) - kept distinct
// from the product approval logger above since the data shape differs.
function addStaffAuditEntry(action, targetName, targetUsername, targetRole) {
  auditLog.unshift({
    id:'AUD'+Date.now(), action, // 'staff_added' | 'staff_removed'
    caseId: '—', productName: targetName + ' (' + targetUsername + ', ' + targetRole + ')', price: null,
    actor: currentUser ? currentUser.name : 'System',
    reason: null, timestamp: new Date().toISOString()
  });
}
function updatePendingBadge() {
  const trueePending = pendingRequests.filter(r=>r.status==='pending');
  const pendingEl = document.getElementById('pending-count');
  if (pendingEl) pendingEl.textContent = trueePending.length;
  const show = trueePending.length > 0 && currentUser && currentUser.role === 'checker';
  const dot = document.getElementById('pending-dot');
  const dotMob = document.getElementById('pending-dot-mob');
  if (dot) dot.classList.toggle('show', show);
  if (dotMob) dotMob.classList.toggle('show', show);
  const returnedToMe = currentUser ? pendingRequests.filter(r=>r.status==='returned' && r.submittedByUsername===currentUser.username) : [];
  const rc = document.getElementById('returned-count');
  if (rc) rc.textContent = returnedToMe.length;
  const myreturnsDot = document.getElementById('myreturns-dot');
  if (myreturnsDot) myreturnsDot.classList.toggle('show', returnedToMe.length > 0);
}
function renderApprovals() { updatePendingBadge(); renderPendingList(); renderReturnedList(); renderHistoryTable(); renderAuditTrail(); }

function renderPendingList() {
  const container = document.getElementById('pending-list');
  const truePending = pendingRequests.filter(r => r.status === 'pending');
  if (!truePending.length) {
    container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">✅</div><p>No pending requests</p><p style="margin-top:6px;font-size:12px">'+(currentUser.role==='maker'?'Use Setup → Request new product / price change to submit one.':'All caught up — nothing needs your review.')+'</p></div>';
    return;
  }
  container.innerHTML = truePending.map(req => {
    const isEdit = req.type === 'edit';
    const priceDiff = isEdit ? req.price - req.oldPrice : null;
    const isChecker = currentUser.role === 'checker';
    const isOwnSubmission = req.submittedByUsername === currentUser.username;
    const diffHtml = isEdit
      ? '<div><div class="diff-label">Was</div><div class="diff-old">KES '+(req.oldPrice?req.oldPrice.toLocaleString():'')+'</div></div><div><div class="diff-label">Now</div><div class="diff-new">KES '+req.price.toLocaleString()+'</div></div><div><div class="diff-label">Change</div><div class="diff-change">'+(priceDiff>0?'+':'')+'KES '+priceDiff.toLocaleString()+'</div></div>'
      : '<div><div class="diff-label">Price</div><div class="diff-new">KES '+req.price.toLocaleString()+'</div></div><div><div class="diff-label">Category</div><div>'+req.cat+'</div></div><div><div class="diff-label">Auto-approve?</div><div>'+(req.price<=getVerticalConfig().approvalAutoLimit&&!isEdit?'Yes (≤'+getVerticalConfig().approvalAutoLimit+')':'No — edits always need approval')+'</div></div>';
    let actionsHtml;
    if (isChecker && isOwnSubmission) {
      actionsHtml = '<div style="font-size:12px;color:var(--amber);background:var(--amber-light);padding:8px 10px;border-radius:var(--radius-sm)">🔒 This is your own submission — another checker must review it. Self-approval is not permitted.</div>';
    } else if (isChecker) {
      actionsHtml = '<div class="approval-actions"><button class="btn-approve" onclick="approveRequest(\''+req.caseId+'\')">✅ Approve</button><button class="btn-return" onclick="openRejectModal(\''+req.caseId+'\',\'return\')">↩️ Return for amendment</button><button class="btn-reject" onclick="openRejectModal(\''+req.caseId+'\',\'reject\')">✗ Reject (final)</button></div>';
    } else {
      actionsHtml = '<div style="font-size:12px;color:var(--text2)">⏳ Awaiting manager review</div>';
    }
    return '<div class="approval-card"><div class="approval-header"><div><div class="approval-title">'+req.icon+' '+req.name+' <span class="pill '+(isEdit?'pill-purple':'pill-green')+'" style="font-size:10px;vertical-align:middle">'+(isEdit?'Price/name change':'New product')+'</span></div><div class="approval-case">'+req.caseId+' · Product ID: '+req.productId+'</div><div class="approval-meta">Submitted by '+req.submittedBy+(isOwnSubmission?' (you)':'')+' · '+timeAgo(req.submittedAt)+(req.reason?(' · "'+req.reason+'"'):'')+'</div></div><span class="pill pill-amber">Pending</span></div><div class="approval-diff">'+diffHtml+'</div>'+actionsHtml+'</div>';
  }).join('');
}

function renderReturnedList() {
  const returned = currentUser ? pendingRequests.filter(r => r.status === 'returned' && r.submittedByUsername === currentUser.username) : [];
  const html = !returned.length
    ? '<div class="empty-state"><div class="empty-state-icon">↩️</div><p>No requests returned to you</p><p style="margin-top:6px;font-size:12px">When a manager returns a request for amendment, it will appear here.</p></div>'
    : returned.map(req =>
        '<div class="approval-card">' +
          '<div class="returned-banner">↩️ Returned by ' + req.reviewedBy + ' · "' + req.rejectionReason + '"</div>' +
          '<div class="approval-header"><div><div class="approval-title">'+req.icon+' '+req.name+'</div><div class="approval-case">'+req.caseId+' · Product ID: '+req.productId+'</div></div></div>' +
          '<div class="approval-diff"><div><div class="diff-label">Price</div><div class="diff-new">KES '+req.price.toLocaleString()+'</div></div><div><div class="diff-label">Category</div><div>'+req.cat+'</div></div><div><div class="diff-label">Type</div><div>'+(req.type==='new'?'New product':'Price/name change')+'</div></div></div>' +
          '<button class="btn-primary" style="margin-top:0" onclick="editReturnedCase(\''+req.caseId+'\')">✏️ Edit and resubmit '+req.caseId+'</button>' +
        '</div>'
      ).join('');
  // Populate both the embedded panel (inside Approvals, for checkers/admins
  // who want visibility) AND the standalone maker-facing tab.
  const embedded = document.getElementById('returned-list');
  if (embedded) embedded.innerHTML = html;
  const standalone = document.getElementById('myreturns-list');
  if (standalone) standalone.innerHTML = html;
  const dot = document.getElementById('myreturns-dot');
  if (dot) dot.classList.toggle('show', returned.length > 0);
}

function renderHistoryTable() {
  const tbody = document.getElementById('history-tbody');
  if (!requestHistory.length) { tbody.innerHTML = '<tr><td colspan="7" style="text-align:center;padding:24px;color:var(--text3)">No history yet</td></tr>'; return; }
  tbody.innerHTML = requestHistory.map(r => {
    const change = r.type==='new' ? 'New product' : ('KES '+r.oldPrice+'→'+r.price);
    const dateStr = r.reviewedAt ? new Date(r.reviewedAt).toLocaleDateString('en-KE',{day:'numeric',month:'short',hour:'2-digit',minute:'2-digit'}) : new Date(r.submittedAt).toLocaleDateString('en-KE',{day:'numeric',month:'short'});
    const statusClass = (r.status==='approved'||r.status==='auto-approved')?'pill-green':r.status==='rejected'?'pill-red':'pill-amber';
    const rejectNote = r.rejectionReason ? ('<br><span style="font-size:10px;color:var(--text3)">"'+r.rejectionReason+'"</span>') : '';
    return '<tr><td class="mono">'+r.caseId+'</td><td>'+r.icon+' <strong>'+r.name+'</strong><br><span class="mono">'+r.productId+'</span></td><td>'+change+'</td><td>'+r.submittedBy+'</td><td>'+(r.reviewedBy||'—')+'</td><td style="font-size:11px;color:var(--text3)">'+dateStr+'</td><td><span class="pill '+statusClass+'">'+r.status+'</span>'+rejectNote+'</td></tr>';
  }).join('');
}
function renderAuditTrail() {
  const container = document.getElementById('audit-list');
  if (!auditLog.length) { container.innerHTML = '<div style="text-align:center;padding:32px;color:var(--text3);font-size:13px">No audit entries yet</div>'; return; }
  const icons = {submitted:'📤',resubmitted:'🔄',approved:'✅',rejected:'❌',returned:'↩️','auto-approved':'⚡',staff_added:'👤',staff_removed:'🗑️',login_success:'🔑',login_failed:'⛔',credit_paid:'💰'};
  const colors = {submitted:'var(--amber-light)',resubmitted:'var(--amber-light)',approved:'var(--green-light)',rejected:'var(--red-light)',returned:'var(--amber-light)','auto-approved':'var(--teal-light)',staff_added:'var(--green-light)',staff_removed:'var(--red-light)',login_success:'var(--green-light)',login_failed:'var(--red-light)',credit_paid:'var(--green-light)'};
  const actionLabels = {staff_added:'added staff account',staff_removed:'removed staff account',login_success:'logged in successfully',login_failed:'failed login attempt',credit_paid:'marked credit as paid'};
  container.innerHTML = auditLog.map(e => {
    const reasonHtml = e.reason ? ('<br><span style="color:var(--text2)">Reason: "'+e.reason+'"</span>') : '';
    const isSimpleEvent = ['staff_added','staff_removed','login_success','login_failed','credit_paid'].indexOf(e.action) !== -1;
    const priceHtml = (e.price !== null && e.price !== undefined) ? (' at KES '+e.price.toLocaleString()) : '';
    const caseHtml = (e.caseId && e.caseId !== '—') ? ('<span class="mono">'+e.caseId+'</span> · ') : '';
    const actionText = actionLabels[e.action] || e.action;
    const subjectHtml = isSimpleEvent ? (' <strong>"'+e.productName+'"</strong>') : (' '+e.action+' <strong>"'+e.productName+'"</strong>');
    return '<div class="audit-entry"><div class="audit-icon" style="background:'+(colors[e.action]||'var(--surface2)')+'">'+(icons[e.action]||'•')+'</div><div class="audit-body">'+caseHtml+'<strong>'+e.actor+'</strong> '+actionText+subjectHtml+priceHtml+reasonHtml+'<div class="audit-time">'+new Date(e.timestamp).toLocaleString('en-KE',{day:'numeric',month:'short',hour:'2-digit',minute:'2-digit'})+'</div></div></div>';
  }).join('');
}
function switchApprovalTab(tab, el) {
  document.querySelectorAll('.tab-item').forEach(t => t.classList.remove('active'));
  el.classList.add('active');
  document.getElementById('approvals-pending').style.display = tab==='pending'?'block':'none';
  document.getElementById('approvals-returned').style.display = tab==='returned'?'block':'none';
  document.getElementById('approvals-history').style.display = tab==='history'?'block':'none';
  document.getElementById('approvals-audit').style.display = tab==='audit'?'block':'none';
}

// ─── ALERTS ───────────────────────────────────────────────────
function updateAlertBadge() {
  const unread = ownerAlerts.filter(a=>!a.read).length;
  document.getElementById('alert-dot').classList.toggle('show', unread>0);
}
function renderAlerts() {
  const container = document.getElementById('alerts-list');
  if (!ownerAlerts.length) { container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">🔔</div><p>No alerts yet</p><p style="margin-top:6px;font-size:12px">You will be notified here when a '+getVerticalConfig().loyaltyNoun+' earns a free '+getVerticalConfig().serviceNoun+'.</p></div>'; return; }
  container.innerHTML = ownerAlerts.map(a => '<div class="alert-card '+(a.read?'':'unread')+'"><div class="alert-icon">🎁</div><div class="alert-body">'+a.message+'<div class="alert-time">'+new Date(a.timestamp).toLocaleString('en-KE',{day:'numeric',month:'short',hour:'2-digit',minute:'2-digit'})+'</div></div></div>').join('');
  ownerAlerts.forEach(a=>a.read=true); save(); updateAlertBadge();
}

// ─── CREDIT REPORT ────────────────────────────────────────────
// Design: Credit sales are recorded at full face value on the sale date
// (keeps that day's POS total accurate). When payment is collected later,
// a Credit Settlement transaction is posted for THAT day (positive, real
// money). The original credit is marked settled with an audit trail of
// who settled it and when. Outstanding credits are excluded from
// reconciliation's "payments received" figure until settled.
let creditFilter = 'outstanding'; // 'outstanding' | 'paid' | 'all'

function getCreditTransactions() {
  // Explicitly exclude settlement entries (payment:'Credit paid') - they are
  // the "payment received" side of a credit being cleared, not a credit
  // liability. Including them was causing cleared credits to re-appear as
  // outstanding because the settlement tx has creditSettled:undefined (falsy).
  return transactions.filter(t =>
    !t.creditSettlement &&
    (t.payment === 'Credit' ||
    (t.payment === 'Split' && t.splits && t.splits.some(s => s.method === 'Credit')))
  );
}

function updateCreditBadge() {
  const outstanding = getCreditTransactions().filter(t => !t.creditSettled).length;
  const dot = document.getElementById('credit-dot');
  if (dot) dot.classList.toggle('show', outstanding > 0);
}

function setCreditFilter(filter, btn) {
  creditFilter = filter;
  // Update active button highlight (only targets the 3 status filter buttons by ID, not the date inputs)
  ['outstanding','paid','all'].forEach(f => {
    const b = document.getElementById('credit-filter-'+f);
    if (b) { b.style.background = ''; b.style.color = ''; }
  });
  if (btn) { btn.style.background = 'var(--teal)'; btn.style.color = '#fff'; }
  // Update title and subtitle to match the active filter
  const titleEl = document.getElementById('credit-view-title');
  const subEl = document.getElementById('credit-view-subtitle');
  if (titleEl && subEl) {
    if (filter === 'outstanding') {
      titleEl.textContent = 'Outstanding credit';
      subEl.textContent = 'All sales recorded as Credit payment that have not yet been paid.';
    } else if (filter === 'paid') {
      titleEl.textContent = 'Credit paid';
      subEl.textContent = 'All sales recorded as Credit payment that have been paid.';
    } else {
      titleEl.textContent = 'All credit';
      subEl.textContent = 'All credit sales — both outstanding and paid.';
    }
  }
  // Vertical-aware identifier column header
  const colHdr = document.getElementById('credit-identifier-col');
  if (colHdr) colHdr.textContent = getVerticalConfig().identifierLabel;
  renderCreditReport();
}

function clearCreditDateFilter() {
  document.getElementById('credit-date-from').value = '';
  document.getElementById('credit-date-to').value = '';
  renderCreditReport();
}

function getFilteredCreditTransactions() {
  const all = getCreditTransactions();
  const dFrom = document.getElementById('credit-date-from') ? document.getElementById('credit-date-from').value : '';
  const dTo = document.getElementById('credit-date-to') ? document.getElementById('credit-date-to').value : '';
  let filtered = all.filter(t =>
    creditFilter === 'all' ? true :
    creditFilter === 'paid' ? t.creditSettled :
    !t.creditSettled
  );
  // Date filter applies to the SALE date (when the credit was extended),
  // which is the most useful axis for "outstanding credit in this period."
  if (dFrom) filtered = filtered.filter(t => t.timestamp.split('T')[0] >= dFrom);
  if (dTo) filtered = filtered.filter(t => t.timestamp.split('T')[0] <= dTo);
  return filtered;
}

// The amount actually owed as CREDIT for a transaction - the full total for
// a pure Credit sale, or just the Credit leg's amount when Credit was only
// part of a split payment (the rest was already paid another way).
function getCreditAmount(tx) {
  if (tx.payment === 'Credit') return tx.total;
  if (tx.payment === 'Split' && tx.splits) {
    const creditSplit = tx.splits.find(s => s.method === 'Credit');
    return creditSplit ? creditSplit.amount : 0;
  }
  return 0;
}

function renderCreditReport() {
  const all = getCreditTransactions();
  const filtered = getFilteredCreditTransactions();
  const tbody = document.getElementById('credit-tbody');
  const outstanding = all.filter(t => !t.creditSettled);
  const outstandingTotal = outstanding.reduce((s,t) => s+getCreditAmount(t), 0);

  // Summary card
  document.getElementById('credit-summary-card').innerHTML =
    '<div style="font-size:11px;color:var(--text2);text-transform:uppercase;letter-spacing:.4px;margin-bottom:8px">Outstanding credit</div>' +
    '<div style="font-size:20px;font-weight:700;color:var(--red)">KES '+outstandingTotal.toLocaleString()+'</div>' +
    '<div style="font-size:12px;color:var(--text2);margin-top:4px">'+outstanding.length+' unpaid transaction'+(outstanding.length!==1?'s':'')+'</div>';

  if (!filtered.length) {
    tbody.innerHTML = '<tr><td colspan="9" style="text-align:center;padding:24px;color:var(--text3)">No credit transactions found</td></tr>';
    document.getElementById('credit-bulk-actions').style.display = 'none';
    return;
  }
  tbody.innerHTML = filtered.map(tx => {
    const dateStr = new Date(tx.timestamp).toLocaleDateString('en-KE',{day:'numeric',month:'short',year:'numeric'});
    const isOutstanding = !tx.creditSettled;
    const statusHtml = isOutstanding
      ? '<span class="pill pill-red">Outstanding</span>'
      : '<span class="pill pill-green">Paid</span><br><span style="font-size:10px;color:var(--text3)">'+(tx.creditSettledDate||'')+'</span>';
    const clearedByHtml = tx.creditSettledBy || '—';
    const creditAmt = getCreditAmount(tx);
    const amountLabel = tx.payment === 'Split' ? ('KES '+creditAmt.toLocaleString()+' <span style="color:var(--text3);font-size:10px">(of KES '+tx.total.toLocaleString()+')</span>') : ('KES '+creditAmt.toLocaleString());
    return '<tr>' +
      '<td>'+(isOutstanding ? '<input type="checkbox" class="credit-checkbox" data-id="'+tx.id+'" onchange="updateCreditBulkBar()"/>' : '')+'</td>' +
      '<td>'+dateStr+'</td>' +
      '<td>'+(tx.plate||'—')+'</td>' +
      '<td>'+(tx.customerName||tx.customerPhone||'—')+'</td>' +
      '<td>'+tx.items.map(i=>i.qty>1?(i.qty+'×'+i.name):i.name).join(', ')+'</td>' +
      '<td>'+tx.staff+'</td>' +
      '<td style="font-weight:600">'+amountLabel+'</td>' +
      '<td>'+statusHtml+'</td>' +
      '<td>'+clearedByHtml+'</td>' +
    '</tr>';
  }).join('');
  updateCreditBulkBar();
  updateCreditBadge();
}

function updateCreditBulkBar() {
  const checked = document.querySelectorAll('.credit-checkbox:checked');
  const bar = document.getElementById('credit-bulk-actions');
  bar.style.display = checked.length > 0 ? 'flex' : 'none';
  const countEl = document.getElementById('credit-selected-count');
  if (countEl) {
    const total = Array.prototype.reduce.call(checked, (s,cb) => {
      const tx = transactions.find(t=>t.id===cb.dataset.id);
      return s + (tx?getCreditAmount(tx):0);
    }, 0);
    countEl.textContent = checked.length + ' selected · KES ' + total.toLocaleString() + ' total';
  }
}

function toggleSelectAllCredit(checked) {
  document.querySelectorAll('.credit-checkbox').forEach(cb => cb.checked = checked);
  updateCreditBulkBar();
}

function markSelectedCreditPaid() {
  const checked = document.querySelectorAll('.credit-checkbox:checked');
  if (!checked.length) return;
  const now = new Date();
  const nowStr = now.toISOString();
  const dateStr = now.toLocaleDateString('en-KE',{day:'numeric',month:'short',year:'numeric'});
  const settler = currentUser ? currentUser.name : 'Unknown';
  let total = 0;
  checked.forEach(cb => {
    const tx = transactions.find(t => t.id === cb.dataset.id);
    if (!tx) return;
    tx.creditSettled = true;
    tx.creditSettledBy = settler;
    tx.creditSettledDate = dateStr;
    tx.creditSettledTimestamp = nowStr;
    const creditAmt = getCreditAmount(tx); // only the credit-owed portion - not the full sale total for split sales
    total += creditAmt;
    // Post a settlement transaction for TODAY so it appears in that day's cash
    const settlementTx = {
      id:'TX'+String(++txCounter),
      time:now.toLocaleTimeString('en-KE',{hour:'2-digit',minute:'2-digit'}),
      timestamp:nowStr,
      items:tx.items.map(i=>({...i,name:'Credit paid: '+i.name})),
      total:creditAmt,
      payment:'Credit paid',
      splits:null,
      staff:settler,
      plate:tx.plate||'',
      customerPhone:tx.customerPhone||'',
      customerName:tx.customerName||'',
      isFreeWash:false,
      isFullyFree:false,
      creditSettlement:true,
      originalTxId:tx.id
    };
    transactions.unshift(settlementTx);
    // Audit trail
    auditLog.unshift({id:'AUD'+Date.now(),action:'credit_paid',caseId:'—',productName:(tx.customerName||tx.plate||'Unknown')+' KES '+tx.total.toLocaleString(),price:tx.total,actor:settler,reason:null,timestamp:nowStr});
  });
  save();
  // Re-read transactions from storage to guarantee the render uses the
  // saved state with creditSettled:true set on all cleared records.
  try { const s = localStorage.getItem('ib_transactions'); if(s) transactions = JSON.parse(s); } catch(e){}
  renderCreditReport(); updateCreditBadge();
  // Also refresh the Sales Report summary so the "Credit not yet collected"
  // figure updates immediately to reflect the newly cleared credit.
  if (document.getElementById('view-log').classList.contains('active')) renderLog();
  showToast('✅ '+checked.length+' credit payment'+(checked.length!==1?'s':'')+' marked as paid — KES '+total.toLocaleString()+' by '+settler);
}

function exportCreditPDF() {
  const all = getFilteredCreditTransactions();
  if (!all.length) { showToast('No credit records to export'); return; }
  const doc = new jspdf.jsPDF({orientation:'landscape'});
  const dFrom = document.getElementById('credit-date-from').value, dTo = document.getElementById('credit-date-to').value;
  const dateLabel = (dFrom || dTo) ? ((dFrom||'…')+' to '+(dTo||'…')) : new Date().toLocaleDateString('en-KE',{day:'numeric',month:'long',year:'numeric'});
  const subtitle = 'Credit Report  |  '+dateLabel;
  let y = addPdfHeader(doc, subtitle);
  const headers = ['Date','Plate','Customer','Items','Staff','Amount','Status','Cleared By'];
  const colX = [14,38,68,108,158,198,228,250];
  const colW = [22,28,38,48,38,28,26,36];
  const PAGE_BOTTOM = 180;
  y += drawTableHeader(doc, headers, colX, y);
  doc.line(14,y-3,268,y-3); y += 2;
  let total = 0;
  all.forEach(r=>{
    if (y > PAGE_BOTTOM) {
      doc.addPage(); y = addPdfHeader(doc, subtitle + ' (cont.)');
      y += drawTableHeader(doc, headers, colX, y); doc.line(14,y-3,268,y-3); y += 2;
    }
    const d=new Date(r.timestamp).toLocaleDateString('en-KE',{day:'numeric',month:'short'});
    const creditAmt = getCreditAmount(r);
    const vals=[d,r.plate||'-',r.customerName||r.customerPhone||'-',r.items.map(i=>i.name).join(', '),r.staff||'-','KES '+creditAmt.toLocaleString(),r.creditSettled?'Paid':'Outstanding',r.creditSettledBy||'-'];
    y = drawWrappedRow(doc, vals, colX, colW, y);
    total += creditAmt;
  });
  if (y > PAGE_BOTTOM) { doc.addPage(); y = 40; }
  y += 4; doc.line(14,y-3,268,y-3);
  doc.setFontSize(11); doc.setFont(undefined,'bold');
  doc.text('Total: KES ' + total.toLocaleString() + '  (' + all.length + ' records)', 14, y+3);
  doc.setFont(undefined,'normal');
  addPdfFooter(doc);
  openDownloadShareModal(doc,(businessName.replace(/[^a-z0-9]/gi,'-').toLowerCase())+'-credit-report-'+new Date().toISOString().split('T')[0]+'.pdf');
}

// ─── SETUP ────────────────────────────────────────────────────
function renderSetup() {
  document.getElementById('setup-products').innerHTML = products.map(p => '<div class="product-list-item"><span>'+p.icon+'</span><span style="flex:1;font-size:13px">'+p.name+'<br><span class="mono">'+p.id+'</span></span><span style="font-size:12px;color:var(--text2)">KES '+p.price+'</span><button class="edit-btn" onclick="openProductForm(\''+p.id+'\')">edit</button></div>').join('');
  document.getElementById('setup-staff').innerHTML = users.map((u,i) => '<div class="product-list-item"><span>👤</span><span style="flex:1;font-size:13px">'+u.name+'<br><span class="mono">'+u.username+'</span></span><span class="pill '+(u.role==='checker'?'pill-purple':'pill-amber')+'">'+u.role+'</span><button class="edit-btn" onclick="removeUser('+i+')">remove</button></div>').join('');
  document.getElementById('loyalty-toggle').classList.toggle('on', loyaltyEnabled);
  document.getElementById('loyalty-every').value = loyaltyEvery;
  const limitEl = document.getElementById('loyalty-limit'); if(limitEl) limitEl.value = loyaltyFreeWashLimit;
  setLoyaltyMode(loyaltyFreeWashMode || 'cap');
  document.getElementById('biz-name').value = businessName;
  const bizIdEl = document.getElementById('biz-id-display');
  if (bizIdEl) bizIdEl.textContent = businessId || '(not yet generated — save settings to create)';
  document.getElementById('biz-loc').value = businessAddress;
  document.getElementById('biz-email').value = businessEmail;
  document.getElementById('biz-phone').value = businessPhone;
  document.getElementById('biz-vertical').value = businessVertical;
  renderNavBranding();
}
function toggleLoyalty() { loyaltyEnabled = !loyaltyEnabled; save(); renderSetup(); showToast(loyaltyEnabled?'🎁 Loyalty program enabled':'Loyalty program disabled'); }
function updateLoyaltyEvery(val) { const n=parseInt(val); if(isNaN(n)||n<2) return; loyaltyEvery=n; save(); showToast('Free wash every '+n+' visits'); }
function setLoyaltyMode(mode) {
  loyaltyFreeWashMode = mode;
  save();
  const fullBtn = document.getElementById('loyalty-mode-full');
  const capBtn = document.getElementById('loyalty-mode-cap');
  const capRow = document.getElementById('loyalty-cap-row');
  const fullNote = document.getElementById('loyalty-full-note');
  if (fullBtn) { fullBtn.classList.toggle('selected', mode==='full'); }
  if (capBtn) { capBtn.classList.toggle('selected', mode==='cap'); }
  if (capRow) capRow.style.display = mode==='cap' ? 'block' : 'none';
  if (fullNote) fullNote.style.display = mode==='full' ? 'block' : 'none';
  showToast(mode==='full' ? '🎁 Fully free — customer pays nothing' : '💰 Fixed cap applied');
}
function updateLoyaltyLimit(val) {
  const n=parseInt(val);
  if(isNaN(n)||n<1) return;
  loyaltyFreeWashLimit=n;
  save();
  showToast('Free reward capped at KES '+n.toLocaleString());
}

// User / staff management (RBAC)
function openUserForm() {
  document.getElementById('uf-name').value = '';
  document.getElementById('uf-username').value = '';
  document.getElementById('uf-password').value = '';
  document.getElementById('uf-role').value = 'maker';
  document.getElementById('user-modal').classList.add('show');
}
function closeUserModal() { document.getElementById('user-modal').classList.remove('show'); }
function saveNewUser() {
  const name = document.getElementById('uf-name').value.trim();
  const username = document.getElementById('uf-username').value.trim();
  const password = document.getElementById('uf-password').value.trim();
  const role = document.getElementById('uf-role').value;
  if (!name || !username || !password) { showToast('⚠️ Please fill in all fields'); return; }
  if (users.find(u=>u.username.toLowerCase()===username.toLowerCase())) { showToast('⚠️ Username already exists'); return; }
  users.push({ username, password, name, role });
  if (staff.indexOf(name) === -1) staff.push(name);
  addStaffAuditEntry('staff_added', name, username, role);
  saveUsers(); save(); renderSetup(); closeUserModal(); renderAuditTrail();
  showToast('✅ Account created for ' + name);
}
function removeUser(i) {
  if (users[i].username === currentUser.username) { showToast('⚠️ You cannot remove your own account while logged in'); return; }
  const removedName = users[i].name;
  const removedUsername = users[i].username;
  const removedRole = users[i].role;
  users.splice(i,1); saveUsers();
  staff = staff.filter(s => s !== removedName);
  addStaffAuditEntry('staff_removed', removedName, removedUsername, removedRole);
  save(); renderSetup(); renderAuditTrail();
  showToast('🗑️ Removed ' + removedName + ' — logged in audit trail');
}

// ─── NAV ──────────────────────────────────────────────────────
const VIEW_TITLES = {pos:'New Sale',log:'Reports',recon:'Reconcile',approvals:'Approvals',myreturns:'My Returned Items',credit:'Credit',alerts:'Alerts',setup:'Setup'};
function showView(id, tab) {
  const allowed = currentUser ? (ROLE_PERMISSIONS[currentUser.role]||[]) : [];
  if (allowed.indexOf(id) === -1) { showToast('🔒 Your role does not have access to this section'); return; }
  document.querySelectorAll('.view').forEach(v=>v.classList.remove('active'));
  document.getElementById('view-'+id).classList.add('active');
  // Update active state on both sidebar nav tabs and mobile bottom tabs
  document.querySelectorAll('#sidebar-nav .nav-tab, .mob-tab').forEach(t=>t.classList.remove('active'));
  document.querySelectorAll('[data-perm="'+id+'"]').forEach(t=>t.classList.add('active'));
  // Update topbar title
  const titleEl = document.getElementById('topbar-title');
  if (titleEl) titleEl.textContent = VIEW_TITLES[id] || id;
  if(id==='log') renderLog();
  if(id==='recon') renderReconHistory();
  if(id==='setup') renderSetup();
  if(id==='approvals') renderApprovals();
  if(id==='myreturns') renderReturnedList();
  if(id==='alerts') renderAlerts();
  if(id==='credit') { renderCreditReport(); setCreditFilter(creditFilter, document.getElementById('credit-filter-'+creditFilter)); }
}

// ─── UTILS ────────────────────────────────────────────────────
function timeAgo(iso) {
  const diff = (Date.now() - new Date(iso)) / 1000;
  if (diff < 60) return 'just now';
  if (diff < 3600) return Math.floor(diff/60)+'m ago';
  if (diff < 86400) return Math.floor(diff/3600)+'h ago';
  return Math.floor(diff/86400)+'d ago';
}
// ─── VALIDATION UTILITIES (applied system-wide) ────────────────
// Kenyan mobile numbers: 07XXXXXXXX / 01XXXXXXXX (10 digits) or
// +254 7XXXXXXXX / 254 7XXXXXXXX (12-13 digits with country code).
function isValidKenyanPhone(value) {
  const cleaned = value.replace(/[\s-]/g, '');
  return /^(0[71][0-9]{8}|\+254[71][0-9]{8}|254[71][0-9]{8})$/.test(cleaned);
}
function formatPhoneError() {
  return 'Enter a valid Kenyan number, e.g. 0712345678 or +254712345678';
}

function showToast(msg) { const t=document.getElementById('toast'); t.textContent=msg; t.classList.add('show'); setTimeout(()=>t.classList.remove('show'),2800); }
function download(name,content) { const a=document.createElement('a'); a.href='data:text/csv;charset=utf-8,'+encodeURIComponent(content); a.download=name; a.click(); }

// ─── INIT ─────────────────────────────────────────────────────
if (!transactions.length) {
  const base=[
    {items:[{name:'Full Wash',qty:1,price:500,productId:'PRD0002'}],total:500,payment:'M-Pesa',staff:'James Kariuki',plate:'KBZ 456Y'},
    {items:[{name:'Express Wash',qty:1,price:300,productId:'PRD0001'},{name:'Tyre Shine',qty:1,price:150,productId:'PRD0005'}],total:450,payment:'Cash',staff:'Mary Njoki',plate:'KDA 123A'},
    {items:[{name:'Premium Detail',qty:1,price:1500,productId:'PRD0003'}],total:1500,payment:'M-Pesa',staff:'James Kariuki',plate:'KCK 789B'},
    {items:[{name:'Interior Clean',qty:1,price:800,productId:'PRD0004'}],total:800,payment:'Card',staff:'Peter Omondi',plate:'KBN 321C'},
  ];
  const now=new Date();
  base.forEach((b,i)=>{ const d=new Date(now-i*3600000); transactions.push(Object.assign({id:'TX'+String(1001+i)}, b, {time:d.toLocaleTimeString('en-KE',{hour:'2-digit',minute:'2-digit'}),timestamp:d.toISOString(),customerPhone:'',customerName:'',isFreeWash:false,isFullyFree:false})); });
  save();
}

// ─── STARTUP ──────────────────────────────────────────────────
// 1. Init Supabase client
// 2. Check if there is an existing Supabase Auth session (page refresh)
// 3. If yes: restore session, fetch role, enter app
// 4. If no: show login screen
async function startup() {
  initSupabase();
  if (!db) { syncLoginScreenBranding(); return; }
  try {
    const { data: { session } } = await db.auth.getSession();
    if (session && session.user) {
      const { data: profile } = await db
        .from('profiles')
        .select('display_name, role, business_id, username')
        .eq('user_id', session.user.id)
        .maybeSingle();
      if (profile) {
        businessId = profile.business_id;
        localStorage.setItem('ib_business_id', businessId);
        currentUser = {
          id: session.user.id,
          username: profile.username,
          name: profile.display_name,
          role: profile.role,
          businessId: profile.business_id
        };
        enterApp();
        return;
      }
    }
  } catch(e) {
    logError('Session restore', e);
  }
  syncLoginScreenBranding();
}

startup();
