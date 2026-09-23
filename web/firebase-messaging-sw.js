importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

const firebaseConfig = {
  apiKey: "AIzaSyA3Ph_KMEyq3jORvbNPESIxr7LEfFzNPS8",
  appId: "1:872541492683:web:a6bbcdf395a6ca3a00924e",
  messagingSenderId: "872541492683",
  projectId: "the-realty-bazaar",
  authDomain: "the-realty-bazaar.firebaseapp.com",
  storageBucket: "the-realty-bazaar.firebasestorage.app",
  measurementId: "G-SHLT4GW6XP"
};

firebase.initializeApp(firebaseConfig);

const messaging = firebase.messaging();
// We do NOT call messaging.onBackgroundMessage() or self.registration.showNotification() here.
// Since the backend sends a "notification" block, Firebase's SDK automatically displays the notification.
// If we also displayed one, it would result in 2 notifications appearing at the same time.
