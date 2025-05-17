const { Client } = require('pg');

const client = new Client({
  host: 'localhost', // e.g., localhost or your PostgreSQL server IP
  port: 5432,                   // Default PostgreSQL port
  user: 'checkin',        // Your PostgreSQL username
  password: '1825Logan305!',    // Your PostgreSQL password
  database: 'checkindb', // The name of your PostgreSQL database
});

client.connect()
  .then(() => console.log('Connected to PostgreSQL'))
  .catch((err) => console.error('Connection error', err.stack));

module.exports = client;

