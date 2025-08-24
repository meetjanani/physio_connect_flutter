const {setGlobalOptions} = require("firebase-functions");
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");

admin.initializeApp();
setGlobalOptions({maxInstances: 10});

const app = express();
app.use(cors({origin: true}));
app.use(bodyParser.json());

app.post("/", async (req, res) => {
  try {
    console.log("Received request body:", JSON.stringify(req.body));

    const {token, title, body} = req.body;

    if (!token || !title || !body) {
      console.error("Missing parameters:", {token, title, body});
      return res.status(400).json({error: "Missing required parameters"});
    }

    const message = {
      notification: {
        title,
        body,
      },
      token: token,
    };

    console.log("Sending message:", JSON.stringify(message));
    const response = await admin.messaging().send(message);
    console.log("FCM response:", response);
    return res.status(200).json({success: true, messageId: response});
  } catch (error) {
    console.error("Error sending notification:", error);
    return res.status(500).json({error: error.message});
  }
});

exports.sendNotification = functions.https.onRequest(app);
