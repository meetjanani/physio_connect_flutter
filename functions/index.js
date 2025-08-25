const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Initialize Firebase Admin SDK
admin.initializeApp();

exports.getFcmToken = functions.https.onCall(async (data, context) => {
  try {
    // Generate token with FCM scope
    const token = await admin.credential.applicationDefault().getAccessToken();

    return {
      token: token.access_token,
      expiryTime: token.expires_in,
    };
  } catch (error) {
    console.error("Error generating FCM token:", error);
    throw new functions.https.HttpsError("internal",
        "Failed to generate token");
  }
});
