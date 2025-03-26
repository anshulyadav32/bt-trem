import { initializeApp } from "firebase/app";

const firebaseConfig = {
  apiKey: "UPDATED_API_KEY",
  authDomain: "UPDATED_AUTH_DOMAIN",
  projectId: "UPDATED_PROJECT_ID",
  storageBucket: "UPDATED_STORAGE_BUCKET",
  messagingSenderId: "UPDATED_MESSAGING_SENDER_ID",
  appId: "UPDATED_APP_ID",
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);

export default app;
