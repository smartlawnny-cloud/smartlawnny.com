// Smart Lawn NY — Email Templates
// Ready for SendGrid integration

var EmailTemplates = {

  orderConfirmation: function(data){
    // data: {customerName, email, items, subtotal, tax, total, receiptNumber, paymentMethod}
    return {
      subject: 'Order Confirmed — Smart Lawn NY (' + (data.receiptNumber||'') + ')',
      html: '<!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width"></head><body style="margin:0;padding:0;font-family:Arial,sans-serif;background:#f4f4f4;">' +
        '<div style="max-width:600px;margin:0 auto;background:#fff;">' +
        '<div style="background:#1d1d1f;padding:24px 32px;text-align:center;">' +
        '<div style="color:#6abb1e;font-size:1.4rem;font-weight:800;">🌿 Smart Lawn NY</div>' +
        '</div>' +
        '<div style="padding:32px;">' +
        '<h1 style="font-size:1.5rem;margin:0 0 8px;">Order Confirmed!</h1>' +
        '<p style="color:#666;margin:0 0 24px;">Hi ' + (data.customerName||'there') + ', thank you for your purchase.</p>' +
        '<div style="background:#f9fafb;border-radius:8px;padding:20px;margin-bottom:24px;">' +
        '<div style="font-size:.8rem;color:#999;margin-bottom:8px;">Receipt: ' + (data.receiptNumber||'') + '</div>' +
        (data.items||[]).map(function(i){ return '<div style="display:flex;justify-content:space-between;padding:8px 0;border-bottom:1px solid #eee;"><span>' + i.name + ' ×' + i.qty + '</span><span style="font-weight:700;">$' + (i.price*i.qty).toFixed(2) + '</span></div>'; }).join('') +
        '<div style="display:flex;justify-content:space-between;padding:8px 0;font-size:.9rem;"><span>Subtotal</span><span>$' + (data.subtotal||0).toFixed(2) + '</span></div>' +
        '<div style="display:flex;justify-content:space-between;padding:8px 0;font-size:.9rem;"><span>Tax</span><span>$' + (data.tax||0).toFixed(2) + '</span></div>' +
        '<div style="display:flex;justify-content:space-between;padding:12px 0 0;font-size:1.2rem;font-weight:800;border-top:2px solid #1d1d1f;"><span>Total</span><span style="color:#6abb1e;">$' + (data.total||0).toFixed(2) + '</span></div>' +
        '</div>' +
        '<div style="background:#f0f8e8;border-radius:8px;padding:20px;margin-bottom:24px;">' +
        '<h3 style="margin:0 0 12px;font-size:1rem;">What happens next:</h3>' +
        '<p style="margin:4px 0;font-size:.9rem;">✅ We\'ll call you within 24 hours to schedule delivery</p>' +
        '<p style="margin:4px 0;font-size:.9rem;">✅ Professional RTK GPS boundary mapping included</p>' +
        '<p style="margin:4px 0;font-size:.9rem;">✅ Full setup, testing, and app walkthrough on-site</p>' +
        '<p style="margin:4px 0;font-size:.9rem;">✅ 2-year manufacturer warranty activated at delivery</p>' +
        '</div>' +
        '<p style="color:#666;font-size:.85rem;">Questions? Call <a href="tel:9143915233" style="color:#6abb1e;">(914) 391-5233</a> or reply to this email.</p>' +
        '</div>' +
        '<div style="background:#1d1d1f;padding:20px 32px;text-align:center;">' +
        '<div style="color:#999;font-size:.75rem;">Smart Lawn NY — smartlawnny.com<br>(914) 391-5233 — smartlawnny@gmail.com</div>' +
        '</div>' +
        '</div></body></html>'
    };
  },

  invoiceSend: function(data){
    // data: {customerName, invoiceNumber, total, dueDate, paymentLink}
    return {
      subject: 'Invoice ' + (data.invoiceNumber||'') + ' — Smart Lawn NY',
      html: '<!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width"></head><body style="margin:0;padding:0;font-family:Arial,sans-serif;background:#f4f4f4;">' +
        '<div style="max-width:600px;margin:0 auto;background:#fff;">' +
        '<div style="background:#1d1d1f;padding:24px 32px;text-align:center;">' +
        '<div style="color:#6abb1e;font-size:1.4rem;font-weight:800;">🌿 Smart Lawn NY</div>' +
        '</div>' +
        '<div style="padding:32px;">' +
        '<h1 style="font-size:1.5rem;margin:0 0 8px;">Invoice ' + (data.invoiceNumber||'') + '</h1>' +
        '<p style="color:#666;margin:0 0 24px;">Hi ' + (data.customerName||'there') + ', here\'s your invoice.</p>' +
        '<div style="background:#f9fafb;border-radius:8px;padding:24px;text-align:center;margin-bottom:24px;">' +
        '<div style="font-size:2.5rem;font-weight:900;color:#6abb1e;">$' + (data.total||0).toFixed(2) + '</div>' +
        '<div style="color:#666;margin-top:4px;">Due by ' + (data.dueDate||'upon receipt') + '</div>' +
        '</div>' +
        (data.paymentLink ? '<a href="' + data.paymentLink + '" style="display:block;background:#6abb1e;color:#fff;text-align:center;padding:16px;border-radius:980px;font-weight:700;font-size:1.1rem;text-decoration:none;margin-bottom:24px;">Pay Now</a>' : '') +
        '<p style="color:#666;font-size:.85rem;">Payment methods: Credit Card, Venmo (@SmartLawnNY), Zelle (smartlawnny@gmail.com), Check</p>' +
        '</div>' +
        '<div style="background:#1d1d1f;padding:20px 32px;text-align:center;">' +
        '<div style="color:#999;font-size:.75rem;">Smart Lawn NY — smartlawnny.com<br>(914) 391-5233 — smartlawnny@gmail.com</div>' +
        '</div>' +
        '</div></body></html>'
    };
  },

  serviceTicketCreated: function(data){
    // data: {customerName, ticketNumber, type, description, scheduledDate}
    return {
      subject: 'Service Ticket ' + (data.ticketNumber||'') + ' — Smart Lawn NY',
      html: '<!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width"></head><body style="margin:0;padding:0;font-family:Arial,sans-serif;background:#f4f4f4;">' +
        '<div style="max-width:600px;margin:0 auto;background:#fff;">' +
        '<div style="background:#1d1d1f;padding:24px 32px;text-align:center;">' +
        '<div style="color:#6abb1e;font-size:1.4rem;font-weight:800;">🌿 Smart Lawn NY</div>' +
        '</div>' +
        '<div style="padding:32px;">' +
        '<h1 style="font-size:1.5rem;margin:0 0 8px;">Service Ticket Created</h1>' +
        '<p style="color:#666;margin:0 0 24px;">Hi ' + (data.customerName||'there') + ', we\'ve created a service ticket for your mower.</p>' +
        '<div style="background:#f9fafb;border-radius:8px;padding:20px;">' +
        '<div style="margin-bottom:8px;"><strong>Ticket:</strong> ' + (data.ticketNumber||'') + '</div>' +
        '<div style="margin-bottom:8px;"><strong>Type:</strong> ' + (data.type||'Service') + '</div>' +
        '<div style="margin-bottom:8px;"><strong>Description:</strong> ' + (data.description||'') + '</div>' +
        (data.scheduledDate ? '<div><strong>Scheduled:</strong> ' + data.scheduledDate + '</div>' : '') +
        '</div>' +
        '<p style="color:#666;font-size:.85rem;margin-top:24px;">We\'ll keep you updated on progress. Call <a href="tel:9143915233" style="color:#6abb1e;">(914) 391-5233</a> with any questions.</p>' +
        '</div>' +
        '<div style="background:#1d1d1f;padding:20px 32px;text-align:center;">' +
        '<div style="color:#999;font-size:.75rem;">Smart Lawn NY — smartlawnny.com<br>(914) 391-5233 — smartlawnny@gmail.com</div>' +
        '</div>' +
        '</div></body></html>'
    };
  }
};
