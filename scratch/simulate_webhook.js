const crypto = require('crypto');
const http = require('http');

const webhookSecret = 'trimly_webhook_secret_123';
const bookingId = process.argv[2];
const tenantId = process.argv[3];

if (!bookingId || !tenantId) {
  console.log('Usage: node simulate_webhook.js <bookingId> <tenantId>');
  process.exit(1);
}

const payload = {
  event: 'payment.captured',
  payload: {
    payment: {
      entity: {
        id: `pay_${crypto.randomBytes(8).toString('hex')}`,
        amount: 50000, // ₹500.00
        currency: 'INR',
        status: 'captured',
        notes: {
          bookingId: bookingId,
          tenantId: tenantId,
        }
      }
    }
  }
};

const rawBody = JSON.stringify(payload);
const signature = crypto
  .createHmac('sha256', webhookSecret)
  .update(rawBody)
  .digest('hex');

const options = {
  hostname: 'localhost',
  port: 4000,
  path: '/api/v1/payments/webhook',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'x-razorpay-signature': signature,
    'Content-Length': Buffer.byteLength(rawBody),
  },
};

const req = http.request(options, (res) => {
  let data = '';
  res.on('data', (chunk) => {
    data += chunk;
  });
  res.on('end', () => {
    console.log(`Status Code: ${res.statusCode}`);
    console.log(`Response: ${data}`);
  });
});

req.on('error', (e) => {
  console.error(`Problem with request: ${e.message}`);
});

req.write(rawBody);
req.end();
