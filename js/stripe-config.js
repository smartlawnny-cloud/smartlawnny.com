/**
 * Stripe Payment Links Configuration
 *
 * HOW TO SET UP:
 * 1. Log into https://dashboard.stripe.com
 * 2. Go to Products > + Add Product for each item below
 * 3. For each product, click "Create payment link"
 * 4. Copy the payment link URL and paste it below
 * 5. Push changes to GitHub to deploy
 *
 * Each product ID matches a data-product attribute on Buy Now buttons.
 */

const STRIPE_LINKS = {
  // Navimow Residential
  'navimow-i215':       '',  // $1,599
  'navimow-h220':       '',  // $2,199
  'navimow-x430':       '',  // $2,499
  'navimow-x450':       '',  // $2,999

  // Navimow Commercial (Terranox)
  'terranox-cm120':     '',  // $5,499
  'terranox-cm240':     '',  // $6,999

  // Yarbo Core Platform
  'yarbo-core':         '',  // $3,994

  // Yarbo Lawn Mower
  'yarbo-mower-bundle':    '',  // $4,994 (Core + Mower)
  'yarbo-mower-module':    '',  // $1,294 (Module only)
  'yarbo-complete-bundle': '',  // $6,194 (Core + Mower + Snow)

  // Yarbo Snow Blower
  'yarbo-snow-bundle':     '',  // $4,994 (Core + Snow)
  'yarbo-snow-module':     '',  // $1,294 (Module only)

  // Installation Add-ons (optional)
  'install-basic':      '',  // $199
  'install-standard':   '',  // $499
  'install-premium':    '',  // $799
};

/**
 * Initialize Stripe buy buttons on page load.
 * Finds all elements with data-product attribute and sets their href.
 * If no Stripe link is configured, shows a contact form fallback.
 */
function initStripeButtons() {
  document.querySelectorAll('[data-product]').forEach(btn => {
    const productId = btn.getAttribute('data-product');
    const link = STRIPE_LINKS[productId];

    if (link && link.length > 0) {
      btn.href = link;
      btn.target = '_blank';
      btn.classList.remove('btn-disabled');
    } else {
      // Fallback: redirect to contact form if Stripe not yet configured
      btn.href = btn.closest('[data-fallback-url]')?.getAttribute('data-fallback-url')
        || (window.location.pathname.includes('/products/') ? '../index.html#contact' : 'index.html#contact');
      btn.removeAttribute('target');
      btn.classList.add('btn-disabled');
    }
  });
}

// Run on DOM ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initStripeButtons);
} else {
  initStripeButtons();
}
