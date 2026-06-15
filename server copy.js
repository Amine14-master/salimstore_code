import express from "express";
import dotenv from "dotenv";
import { fileURLToPath } from "url";
import { dirname, join } from "path";
import {
    ApiError,
    Client,
    Environment,
    LogLevel,
    OrdersController,
    PaymentsController,
} from "@paypal/paypal-server-sdk";
import bodyParser from "body-parser";
import admin from "firebase-admin";

// Get the directory of the current module
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Load environment variables from .env file
dotenv.config({ path: join(__dirname, ".env") });

const app = express();
app.use(bodyParser.json());

const {
    PAYPAL_CLIENT_ID,
    PAYPAL_CLIENT_SECRET,
    PORT = 8080,
    FIREBASE_DATABASE_URL,
    FIREBASE_PROJECT_ID,
    FIREBASE_PRIVATE_KEY,
    FIREBASE_CLIENT_EMAIL,
} = process.env;

// Initialize Firebase Admin SDK
try {
    admin.initializeApp({
        credential: admin.credential.cert({
            type: "service_account",
            project_id: FIREBASE_PROJECT_ID,
            private_key: FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
            client_email: FIREBASE_CLIENT_EMAIL,
        }),
        databaseURL: FIREBASE_DATABASE_URL,
    });
    console.log("✅ Firebase initialized successfully");
} catch (error) {
    console.warn("⚠️ Firebase initialization warning:", error.message);
}

const db = admin.database();

const client = new Client({
    clientCredentialsAuthCredentials: {
        oAuthClientId: PAYPAL_CLIENT_ID,
        oAuthClientSecret: PAYPAL_CLIENT_SECRET,
    },
    timeout: 0,
    environment: Environment.Sandbox,
    logging: {
        logLevel: LogLevel.Info,
        logRequest: { logBody: true },
        logResponse: { logHeaders: true },
    },
});

const ordersController = new OrdersController(client);
const paymentsController = new PaymentsController(client);

/**
 * Create order in Firebase Realtime Database
 * @param {Object} orderData - Complete order data from client
 * @param {string} paypalOrderId - PayPal order ID
 * @returns {Promise<string>} - Generated order ID (BC202406000001)
 */
const createFirebaseOrder = async (orderData, paypalOrderId) => {
    try {
        console.log("\n[Firebase] Creating order in database...");
        
        if (!orderData.userId) {
            throw new Error("userId is required");
        }
        
        const userId = orderData.userId;
        const year = new Date().getFullYear();
        const wilayaCode = (orderData.wilaya || "06").padStart(2, "0");
        
        // Generate order ID: BCYYYYWW00000
        const counterRef = db.ref(`orderCounter/${year}_${wilayaCode}`);
        const snapshot = await counterRef.get();
        
        let orderNumber = 1;
        if (snapshot.exists()) {
            orderNumber = snapshot.val() + 1;
        }
        
        await counterRef.set(orderNumber);
        
        const orderId = `BC${year}${wilayaCode}${orderNumber.toString().padStart(5, "0")}`;
        
        console.log(`[Firebase] Generated order ID: ${orderId}`);
        
        // Prepare order data for Firebase
        const firebaseOrderData = {
            orderId: orderId,
            userId: userId,
            items: (orderData.items || []).map(item => ({
                productId: item.productId || "",
                productName: item.name || "",
                quantity: parseFloat(item.quantity) || 1,
                unit: item.unit || "",
                unitPrice: parseFloat(item.price) || 0,
                totalPrice: parseFloat(item.totalPrice) || 0,
                originalPrice: item.originalPrice ? parseFloat(item.originalPrice) : null,
                discountPercentage: item.discountPercentage ? parseFloat(item.discountPercentage) : null
            })),
            cartTotal: parseFloat(orderData.cartTotal) || 0,
            deliveryFee: parseFloat(orderData.deliveryFee) || 0,
            expressDelivery: parseFloat(orderData.expressFee) > 0,
            expressFee: parseFloat(orderData.expressFee) || 0,
            tip: parseFloat(orderData.tip) || 0,
            total: parseFloat(orderData.finalTotal) || 0,
            currency: "EUR",
            status: "pending",
            deliveryAddress: orderData.deliveryAddress || "",
            deliveryLabel: orderData.deliveryLabel || "",
            wilaya: orderData.wilaya || "",
            wilayaCode: wilayaCode,
            receiverName: orderData.receiverName || "",
            receiverPhone: orderData.receiverPhone || "",
            paymentMethod: "paypal",
            paymentStatus: "completed",
            paypalOrderId: paypalOrderId,
            createdAt: admin.database.ServerValue.TIMESTAMP,
            updatedAt: admin.database.ServerValue.TIMESTAMP
        };
        
        // Save to Firebase
        await db.ref(`orders/${orderId}`).set(firebaseOrderData);
        
        console.log(`[Firebase] ✅ Order saved successfully: ${orderId}\n`);
        
        return orderId;
        
    } catch (error) {
        console.error("[Firebase] Error creating order:", error.message);
        throw error;
    }
};

/**
 * Clear user's cart from Firebase
 * @param {string} userId - User ID
 * @returns {Promise<void>}
 */
const clearUserCart = async (userId) => {
    try {
        console.log(`[Firebase] Clearing cart for user: ${userId}`);
        await db.ref(`userCarts/${userId}`).remove();
        console.log(`[Firebase] ✅ Cart cleared successfully\n`);
    } catch (error) {
        console.error("[Firebase] Warning - could not clear cart:", error.message);
        // Don't throw - cart clearing is optional
    }
};

/**
 * Create an order to start the transaction.
 * @see https://developer.paypal.com/docs/api/orders/v2/#orders_create
 */
const createOrder = async (orderData) => {
   // Calculate the total amount: cartTotal + deliveryFee + expressFee + tip
   const cartTotal = parseFloat(orderData.cartTotal) || 0;
   const deliveryFee = parseFloat(orderData.deliveryFee) || 0;
   const expressFee = parseFloat(orderData.expressFee) || 0;
   const tip = parseFloat(orderData.tip) || 0;
   const totalAmount = (cartTotal + deliveryFee + expressFee + tip).toFixed(2);
   
   console.log(`[PayPal] Creating order with amount: ${totalAmount} EUR`);
   console.log(`  - Cart Total: ${cartTotal}`);
   console.log(`  - Delivery Fee: ${deliveryFee}`);
   console.log(`  - Express Fee: ${expressFee}`);
   console.log(`  - Tip: ${tip}`);

   const payload = {
        body: {
            intent: "CAPTURE",
            purchaseUnits: [
                {
                    amount: {
                        currencyCode: "EUR",
                        value: totalAmount,
                        breakdown: {
                            itemTotal: {
                                currencyCode: "EUR",
                                value: cartTotal.toFixed(2)
                            },
                            shipping: {
                                currencyCode: "EUR",
                                value: (deliveryFee + expressFee).toFixed(2)
                            },
                            taxTotal: {
                                currencyCode: "EUR",
                                value: tip.toFixed(2)
                            }
                        }
                    },
                },
            ],
        },
        prefer: "return=minimal",
    };

    try {
        const { body, ...httpResponse } = await ordersController.createOrder(
            payload
        );
        // Get more response info...
        // const { statusCode, headers } = httpResponse;
        return {
            jsonResponse: JSON.parse(body),
            httpStatusCode: httpResponse.statusCode,
        };
    } catch (error) {
        if (error instanceof ApiError) {
            // const { statusCode, headers } = error;
            throw new Error(error.message);
        }
        // Handle any other errors
        throw error;
    }
};

app.post("/api/orders", async (req, res) => {
    try {
        // use the cart information passed from the front-end to calculate the order amount detals
        const orderData = req.body;
        const { jsonResponse, httpStatusCode } = await createOrder(orderData);
        res.status(httpStatusCode).json(jsonResponse);
    } catch (error) {
        console.error("Failed to create order:", error);
        
        // Provide more specific error messages
        let errorMessage = "Failed to create order.";
        if (error.message) {
            if (error.message.includes("EAI_AGAIN") || error.message.includes("getaddrinfo")) {
                errorMessage = "Network error: Unable to connect to PayPal API. Please check your internet connection.";
            } else if (error.message.includes("401") || error.message.includes("Unauthorized")) {
                errorMessage = "Authentication failed: Invalid PayPal credentials. Please check your CLIENT_ID and CLIENT_SECRET.";
            } else {
                errorMessage = `Failed to create order: ${error.message}`;
            }
        }
        
        res.status(500).json({ error: errorMessage });
    }
});



/**
 * Capture payment for the created order to complete the transaction.
 * @see https://developer.paypal.com/docs/api/orders/v2/#orders_capture
 */
/*const captureOrder = async (orderID) => {
    const collect = {
        id: orderID,
        prefer: "return=minimal",
        body: {}
    };

    try {
        const { body, ...httpResponse } = await ordersController.captureOrder(
            collect
        );
        // Get more response info...
        // const { statusCode, headers } = httpResponse;
        return {
            jsonResponse: JSON.parse(body),
            httpStatusCode: httpResponse.statusCode,
        };
    } catch (error) {
        if (error instanceof ApiError) {
            // const { statusCode, headers } = error;
            throw new Error(error.message);
        }
        // Handle any other errors
        throw error;
    }
};*/
const captureOrder = async (orderID) => {
    try {
        const { body, ...httpResponse } = await ordersController.captureOrder({
            id: orderID,
            prefer: "return=minimal",
        });
        
        return {
            jsonResponse: JSON.parse(body),
            httpStatusCode: httpResponse.statusCode,
        };
    } catch (error) {
        if (error instanceof ApiError) {
            throw new Error(error.message);
        }
        throw error;
    }
};

app.post("/api/orders/:orderID/capture", async (req, res) => {
    try {
        console.log("\n=== CAPTURE ENDPOINT CALLED ===");
        const { orderID } = req.params;
        const orderData = req.body;
        
        console.log(`[PayPal] Capturing order: ${orderID}`);
        
        // Step 1: Capture PayPal payment
        const { jsonResponse, httpStatusCode } = await captureOrder(orderID);
        
        // Step 2: Verify payment was successful
        if (jsonResponse.status !== "COMPLETED") {
            console.error("[PayPal] Payment not completed. Status:", jsonResponse.status);
            return res.status(400).json({
                error: true,
                message: "Payment was not completed",
                status: jsonResponse.status
            });
        }
        
        console.log("[PayPal] ✅ Payment captured successfully");
        
        // Step 3: Create order in Firebase
        let orderId = null;
        try {
            orderId = await createFirebaseOrder(orderData, orderID);
        } catch (firebaseError) {
            console.error("[Firebase] Error creating order:", firebaseError.message);
            // Still return PayPal response but log the Firebase error
            return res.status(500).json({
                error: true,
                message: "Payment captured but order creation failed",
                paypalOrderId: orderID,
                firebaseError: firebaseError.message
            });
        }
        
        // Step 4: Clear user cart (optional)
        if (orderData.userId) {
            try {
                await clearUserCart(orderData.userId);
            } catch (cartError) {
                console.warn("[Firebase] Could not clear cart:", cartError.message);
            }
        }
        
        // Step 5: Return success response with orderId
        const successResponse = {
            orderId: orderId,
            paypalOrderId: orderID,
            status: "COMPLETED",
            purchase_units: jsonResponse.purchase_units,
            message: "Order created successfully"
        };
        
        console.log(`[Success] Order created: ${orderId}`);
        console.log("=== CAPTURE ENDPOINT COMPLETED ===\n");
        
        res.status(httpStatusCode).json(successResponse);
        
    } catch (error) {
        console.error("=== ERROR IN CAPTURE ENDPOINT ===");
        console.error("Error:", error.message);
        res.status(500).json({ 
            error: true,
            message: "Failed to capture order.",
            details: error.message
        });
    }
});


/**
 * Authorize payment for the created order to complete the transaction.
 * @see https://developer.paypal.com/docs/api/orders/v2/#orders_authorize
 */
const authorizeOrder = async (orderID) => {
    const collect = {
        id: orderID,
        prefer: "return=minimal",
    };

    try {
        const { body, ...httpResponse } = await ordersController.authorizeOrder(
            collect
        );
        // Get more response info...
        // const { statusCode, headers } = httpResponse;
        return {
            jsonResponse: JSON.parse(body),
            httpStatusCode: httpResponse.statusCode,
        };
    } catch (error) {
        if (error instanceof ApiError) {
            // const { statusCode, headers } = error;
            throw new Error(error.message);
        }
        // Handle any other errors
        throw error;
    }
};

// authorizeOrder route
app.post("/api/orders/:orderID/authorize", async (req, res) => {
    try {
        const { orderID } = req.params;
        const { jsonResponse, httpStatusCode } = await authorizeOrder(orderID);
        res.status(httpStatusCode).json(jsonResponse);
    } catch (error) {
        console.error("Failed to create order:", error);
        res.status(500).json({ error: "Failed to authorize order." });
    }
});

/**
 * Captures an authorized payment, by ID.
 * @see https://developer.paypal.com/docs/api/payments/v2/#authorizations_capture
 */
const captureAuthorize = async (authorizationId) => {
    const collect = {
        authorizationId: authorizationId,
        prefer: "return=minimal",
        body: {
            finalCapture: false,
        },
    };
    try {
        const { body, ...httpResponse } =
            await paymentsController.captureAuthorize(collect);
        // Get more response info...
        // const { statusCode, headers } = httpResponse;
        return {
            jsonResponse: JSON.parse(body),
            httpStatusCode: httpResponse.statusCode,
        };
    } catch (error) {
        if (error instanceof ApiError) {
            // const { statusCode, headers } = error;
            throw new Error(error.message);
        }
        // Handle any other errors
        throw error;
    }
};

// captureAuthorize route
app.post("/orders/:authorizationId/captureAuthorize", async (req, res) => {
    try {
        const { authorizationId } = req.params;
        const { jsonResponse, httpStatusCode } = await captureAuthorize(
            authorizationId
        );
        res.status(httpStatusCode).json(jsonResponse);
    } catch (error) {
        console.error("Failed to create order:", error);
        res.status(500).json({ error: "Failed to capture authorize." });
    }
});

app.listen(PORT, () => {
    console.log(`\n✅ Node server listening at http://localhost:${PORT}/`);
    console.log(`✅ PayPal credentials loaded successfully`);
    console.log(`✅ Environment: Sandbox\n`);
});