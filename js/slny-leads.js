// js/slny-leads.js — central lead submission for smartlawnny.com.
//
// Routes every public-site form submission to Smart Lawn OS CRM
// (Supabase project zjqpzqpvovvuaxikyksq) via the submit_lead RPC.
// Replaces the older direct writes to project hsjodrniizoctxsznjsy
// (now paused/deleted), which were silently failing.
//
// Surfaces errors instead of swallowing them — caller decides what to show.
// Public anon key + tenant id below are safe to embed (anon by design).

(function(){
  var CRM_URL   = 'https://zjqpzqpvovvuaxikyksq.supabase.co';
  var CRM_KEY   = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpqcXB6cXB2b3Z2dWF4aWt5a3NxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkyNDM4NDYsImV4cCI6MjA5NDgxOTg0Nn0.T6s7o38wKFVPn6XPmJSMQxSflPFV4bjI7oGOqo7dOJg';
  var TENANT_ID = '9ca9340a-bbea-4945-a656-35187423d509';

  function utm(name){
    try { return (new URLSearchParams(location.search)).get(name) || null; }
    catch(e) { return null; }
  }

  /**
   * Submit a lead to the Smart Lawn OS CRM.
   * @param {string} source  e.g. 'website-quote', 'commercial-calculator', 'hoa', 'website'
   * @param {object} payload one or more of:
   *   first_name / firstName, last_name / lastName, email, phone,
   *   address / street, lawn_sqft / lawnSize, message / notes,
   *   source_detail / interest
   * @returns Promise<{ok, lead_id, deduped}> — rejects on failure.
   */
  window.slnySubmitLead = function(source, payload){
    payload = payload || {};
    var body = {
      p_tenant_id:    TENANT_ID,
      p_first_name:   payload.first_name || payload.firstName || null,
      p_last_name:    payload.last_name  || payload.lastName  || null,
      p_email:        payload.email || null,
      p_phone:        payload.phone || null,
      p_address:      payload.address || payload.street || null,
      p_lawn_sqft:    payload.lawn_sqft || payload.lawnSize || null,
      p_source:       source || 'website',
      p_source_detail: payload.source_detail || payload.interest || null,
      p_message:      payload.message || payload.notes || null,
      p_utm_source:   utm('utm_source'),
      p_utm_medium:   utm('utm_medium'),
      p_utm_campaign: utm('utm_campaign'),
      p_landing_page: (location && location.href) || null
    };
    return fetch(CRM_URL + '/rest/v1/rpc/submit_lead', {
      method: 'POST',
      headers: {
        'Content-Type':  'application/json',
        'apikey':        CRM_KEY,
        'Authorization': 'Bearer ' + CRM_KEY
      },
      body: JSON.stringify(body)
    }).then(function(r){
      return r.json().catch(function(){ return null; }).then(function(j){
        if (!r.ok || !j || j.ok === false) {
          throw new Error((j && j.error) || ('Lead save HTTP ' + r.status));
        }
        return j;
      });
    });
  };

  // Back-compat: hoa/index.html calls window.slnySaveLead(source, formData).
  // Old helper wrote raw rows to a leads table on the dead project; new path
  // funnels through submit_lead instead. Same signature, same promise shape.
  window.slnySaveLead = function(source, formData){
    return window.slnySubmitLead(source, formData);
  };
})();
