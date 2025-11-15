const functions = require("firebase-functions");
const admin = require("firebase-admin");
const fetch = require("node-fetch");
admin.initializeApp();

const PAYPAL_CLIENT_ID = "AQMIelY0WV89qOdbiodHg";
const PAYPAL_SECRET = "EKUimYxY8weMcNcqpX_cy4SjdrIGhVJp8Vt4W_tWSzJef8AMRvm6KGZ_7u5OlJWB7i0o5zsmRFGmKaiS";
const PAYPAL_BASE = "https://api-m.sandbox.paypal.com"; // use live URL later

async function getAccessToken() {
  const res = await fetch(`${PAYPAL_BASE}/v1/oauth2/token`, {
    method: "POST",
    headers: {
      "Authorization": "Basic " + Buffer.from(`${PAYPAL_CLIENT_ID}:${PAYPAL_SECRET}`).toString("base64"),
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: "grant_type=client_credentials",
  });
  const data = await res.json();
  return data.access_token;
}

exports.verifyPayPalPayment = functions.https.onCall(async (data, context) => {
  const {orderId, expectedAmount} = data;
  const token = await getAccessToken();

  const res = await fetch(`${PAYPAL_BASE}/v2/checkout/orders/${orderId}`, {
    headers: {Authorization: `Bearer ${token}`},
  });

  const order = await res.json();

  const isValid = order.status === "COMPLETED" &&
                  order.purchase_units[0].amount.value === expectedAmount;

  if (isValid) {
    // store payment info securely
    await admin.database().ref(`payments/${orderId}`).set({
      status: "verified",
      amount: expectedAmount,
      payer: order.payer.email_address || "unknown",
      createdAt: admin.database.ServerValue.TIMESTAMP,
    });
    return {success: true};
  } else {
    return {success: false, details: order};
  }
});
