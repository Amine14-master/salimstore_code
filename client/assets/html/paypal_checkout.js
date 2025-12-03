// Initialize cart data from Flutter
let cartData = window.cartData || {};

// Update UI with cart data
function updateOrderSummary() {
    if (!cartData || !cartData.finalTotal) {
        console.warn('Cart data not available');
        return;
    }

    // Format price helper
    const formatPrice = (price) => {
        return (Math.round(price * 100) / 100).toFixed(2) + '€';
    };

    // Update summary items
    document.getElementById('cartTotal').textContent = formatPrice(cartData.cartTotal || 0);
    document.getElementById('deliveryFee').textContent = formatPrice(cartData.deliveryFee || 0);
    document.getElementById('finalTotal').textContent = formatPrice(cartData.finalTotal || 0);

    // Show express fee if present
    if (cartData.expressFee && cartData.expressFee > 0) {
        document.getElementById('expressFeeContainer').style.display = 'flex';
        document.getElementById('expressFee').textContent = formatPrice(cartData.expressFee);
    }

    // Show tip if present
    if (cartData.tip && cartData.tip > 0) {
        document.getElementById('tipContainer').style.display = 'flex';
        document.getElementById('tipAmount').textContent = formatPrice(cartData.tip);
    }

    console.log('Order summary updated:', cartData);
}

// Wait for PayPal SDK to load before initializing
let retryCount = 0;
const maxRetries = 50; // 5 seconds max wait time

function initializePayPal() {
    retryCount++;

    // Check if PayPal SDK is loaded
    if (typeof paypal === 'undefined' || !paypal.Buttons) {
        if (retryCount < maxRetries) {
            console.log('Waiting for PayPal SDK to load... (attempt ' + retryCount + ')');
            setTimeout(initializePayPal, 100);
            return;
        } else {
            console.error('PayPal SDK failed to load after ' + maxRetries + ' attempts');
            resultMessage('Erreur: Le SDK PayPal n\'a pas pu être chargé. Veuillez vérifier votre connexion Internet et réessayer.', 'error');
            return;
        }
    }

    console.log('PayPal SDK loaded, initializing buttons... (attempt ' + retryCount + ')');

    // Update order summary first
    updateOrderSummary();

    // Render the button component
    paypal
        .Buttons({
            // Sets up the transaction when a payment button is clicked
            createOrder: createOrderCallback,
            onApprove: onApproveCallback,
            onError: function (error) {
                console.error('PayPal button error:', error);
                resultMessage('Erreur PayPal: ' + error.message, 'error');
            },
            style: {
                shape: "rect",
                layout: "vertical",
                color: "gold",
                label: "paypal",
            },
        })
        .render("#paypal-button-container")
        .catch(function (error) {
            console.error('Error rendering PayPal buttons:', error);
            resultMessage('Erreur lors du chargement des boutons PayPal. Veuillez rafraîchir la page.', 'error');
        });

    // Card Fields initialization removed as it is not supported for this region/account
    console.log('PayPal buttons initialized.');
}

// Start initialization when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializePayPal);
} else {
    // DOM is already ready, start initialization
    initializePayPal();
}

// Handle cancel button click
document.addEventListener('DOMContentLoaded', function () {
    const cancelButton = document.getElementById('cancel-button');
    if (cancelButton) {
        cancelButton.addEventListener('click', function () {
            console.log('Cancel button clicked - returning to cart');
            // Send message to Flutter to close the payment screen
            if (window.PayPalCancel && window.PayPalCancel.postMessage) {
                window.PayPalCancel.postMessage('cancel');
            } else {
                // Fallback: try to go back in history
                console.log('PayPalCancel channel not available, using history.back()');
                window.history.back();
            }
        });
    }
});

async function createOrderCallback() {
    resultMessage("");
    const serverUrl = "https://salimstore.onrender.com";

    try {
        console.log("Creating PayPal order with cart data:", cartData);

        // Validate cart data
        if (!cartData || !cartData.items || cartData.items.length === 0) {
            throw new Error("Panier vide ou données invalides");
        }

        // Prepare order payload with complete cart data
        const orderPayload = {
            // User ID (CRITICAL for Firebase)
            userId: cartData.userId || '',

            // Cart items with product details, prices, and quantities
            items: (cartData.items || []).map(item => ({
                id: item.id || '',
                productId: item.productId || '',
                name: item.name || '',
                quantity: parseFloat(item.quantity) || 1,
                unit: item.unit || '',
                price: parseFloat(item.price) || 0,
                totalPrice: parseFloat(item.totalPrice) || 0,
            })),

            // Order totals
            cartTotal: parseFloat(cartData.cartTotal) || 0,
            deliveryFee: parseFloat(cartData.deliveryFee) || 0,
            expressFee: parseFloat(cartData.expressFee) || 0,
            tip: parseFloat(cartData.tip) || 0,
            finalTotal: parseFloat(cartData.finalTotal) || 0,

            // Delivery information
            deliveryAddress: cartData.deliveryAddress || '',
            deliveryLabel: cartData.deliveryLabel || '',
            wilaya: cartData.wilaya || '',

            // Receiver information
            receiverName: cartData.receiverName || '',
            receiverPhone: cartData.receiverPhone || '',

            // Payment metadata
            paymentMethod: 'paypal',
            timestamp: new Date().toISOString(),
        };

        console.log("Order payload being sent:", JSON.stringify(orderPayload, null, 2));
        console.log("PayPal API server URL (from fetch):", serverUrl);

        const response = await fetch(`${serverUrl}/api/orders`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "Accept": "application/json"
            },
            body: JSON.stringify(orderPayload),
        });

        console.log("Response status:", response.status);
        const orderData = await response.json();

        console.log("Order creation response:", orderData);

        if (orderData.id) {
            console.log("PayPal order created successfully:", orderData.id);
            // Store order ID for later use in capture
            window.paypalOrderId = orderData.id;
            return orderData.id;
        } else {
            const errorDetail = orderData?.details?.[0];
            const errorMessage = errorDetail
                ? `${errorDetail.issue} ${errorDetail.description} (${orderData.debug_id})`
                : JSON.stringify(orderData);
            throw new Error(errorMessage);
        }
    } catch (error) {
        console.error("Fetch failed:", error, "URL tried:", serverUrl);
        resultMessage(`Impossible d'initier le paiement PayPal...<br><strong>Erreur JavaScript:</strong> ${error.message}<br><strong>URL:</strong> ${serverUrl}<br><strong>Vérifiez votre connexion réseau et les logs du serveur.</strong>`, 'error');
    }
}

async function onApproveCallback(data, actions) {
    const serverUrl = "https://salimstore.onrender.com";

    try {
        console.log("Capturing PayPal order:", data.orderID);
        console.log("PayPal API server URL (capture):", serverUrl);
        console.log("Cart data for order creation:", cartData);

        // Prepare complete order data for backend
        const completeOrderData = {
            // User ID (CRITICAL for Firebase)
            userId: cartData.userId || '',

            // PayPal order ID
            paypalOrderId: data.orderID,

            // Cart items with all details
            items: (cartData.items || []).map(item => ({
                id: item.id || '',
                productId: item.productId || '',
                name: item.name || '',
                quantity: parseFloat(item.quantity) || 1,
                unit: item.unit || '',
                price: parseFloat(item.price) || 0,
                totalPrice: parseFloat(item.totalPrice) || 0,
            })),

            // Order totals (including tip)
            cartTotal: parseFloat(cartData.cartTotal) || 0,
            deliveryFee: parseFloat(cartData.deliveryFee) || 0,
            expressFee: parseFloat(cartData.expressFee) || 0,
            tip: parseFloat(cartData.tip) || 0,
            finalTotal: parseFloat(cartData.finalTotal) || 0,

            // Delivery information
            deliveryAddress: cartData.deliveryAddress || '',
            deliveryLabel: cartData.deliveryLabel || '',
            wilaya: cartData.wilaya || '',

            // Receiver information
            receiverName: cartData.receiverName || '',
            receiverPhone: cartData.receiverPhone || '',

            // Payment metadata
            paymentMethod: 'paypal',
            paymentStatus: 'completed',
            timestamp: new Date().toISOString(),
        };

        console.log("Complete order data:", JSON.stringify(completeOrderData, null, 2));

        const response = await fetch(`${serverUrl}/api/orders/${data.orderID}/capture`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "Accept": "application/json"
            },
            body: JSON.stringify(completeOrderData),
        });

        console.log("Capture POST status:", response.status);
        const orderData = await response.json();

        console.log("Capture response:", orderData);

        const transaction = orderData?.purchase_units?.[0]?.payments?.captures?.[0] ||
            orderData?.purchase_units?.[0]?.payments?.authorizations?.[0];
        const errorDetail = orderData?.details?.[0];

        if (errorDetail || !transaction || transaction.status === "DECLINED") {
            let errorMessage;
            if (transaction) {
                errorMessage = `Transaction ${transaction.status}: ${transaction.id}`;
            } else if (errorDetail) {
                errorMessage = `${errorDetail.description} (${orderData.debug_id})`;
            } else {
                errorMessage = JSON.stringify(orderData);
            }
            throw new Error(errorMessage);
        } else {
            // Payment successful - order has been created
            const orderId = orderData?.orderId || data.orderID;

            if (!orderId) {
                console.error("ERROR: No orderId in response!", orderData);
                resultMessage(
                    `<strong>⚠ Attention</strong><br>` +
                    `La commande a été créée mais nous n'avons pas reçu le numéro de commande.<br>` +
                    `Veuillez vérifier vos commandes.`,
                    'error'
                );
                // Still redirect after 5 seconds
                setTimeout(() => {
                    window.location.href = '/orders';
                }, 5000);
                return;
            }

            resultMessage(
                `<strong>✓ Transaction réussie!</strong><br>` +
                `Statut: ${transaction.status}<br>` +
                `ID Transaction: ${transaction.id}<br><br>` +
                `<strong>Votre commande a été créée avec succès!</strong><br>` +
                `Numéro de commande: <strong>${orderId}</strong><br><br>` +
                `Redirection vers vos commandes...`,
                'success'
            );
            console.log("Payment and order creation successful");
            console.log("Order ID:", orderId);
            console.log("PayPal Order ID:", data.orderID);
            console.log("Full response:", JSON.stringify(orderData, null, 2));

            // Notify Flutter app of successful payment
            setTimeout(() => {
                console.log("Notifying Flutter app of successful order");

                // Try to use PayPalSuccess channel (Flutter WebView)
                if (window.PayPalSuccess) {
                    console.log("Using PayPalSuccess channel");
                    window.PayPalSuccess.postMessage(orderId);
                }
                // Fallback to flutter_inappwebview
                else if (window.flutter_inappwebview) {
                    console.log("Using flutter_inappwebview handler");
                    window.flutter_inappwebview.callHandler('orderCreated', {
                        orderId: orderId,
                        paypalOrderId: data.orderID,
                        status: 'success'
                    });
                }
                // Fallback for Web (Standard URL redirect)
                else {
                    console.log("Using URL redirect fallback for Web");
                    window.location.href = 'https://salimstore.onrender.com/payment-success?orderId=' + orderId;
                }

                console.log("Payment notification sent, order ID:", orderId);
            }, 500);
        }
    } catch (error) {
        console.error("Fetch failed (capture):", error, "URL:", serverUrl);
        resultMessage(
            `<strong>✗ Erreur lors du traitement du paiement</strong><br><br>` +
            `<strong>Erreur:</strong> ${error.message}<br>` +
            `<strong>URL:</strong> ${serverUrl}<br><br>` +
            `Veuillez vérifier votre connexion réseau et réessayer.`,
            'error'
        );
    }
}

// Example function to show a result to the user
function resultMessage(message, type = 'info') {
    const container = document.querySelector("#result-message");
    container.innerHTML = message;
    container.className = type;
}
