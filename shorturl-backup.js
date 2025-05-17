const express = require('express');
const mongoose = require('mongoose');
const shortid = require('shortid');
const app = express();
const PORT = 3000;
const BASE_URL = 'http://localhost:' + PORT;

// Connect to MongoDB
mongoose.connect('mongodb://127.0.0.1:27017/urlShortener', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

// Define URL schema
const urlSchema = new mongoose.Schema({
  originalUrl: String,
  shortUrl: String,
  alias: { type: String, unique: true },
  clicks: { type: Number, default: 0 },
});

const Url = mongoose.model('Url', urlSchema);

app.use(express.json());
app.use(express.urlencoded({ extended: false }));

// Route to create short URL
app.post('/shorten', async (req, res) => {
  const { originalUrl, alias } = req.body;
  let shortUrl = alias ? alias : shortid.generate();

  // Check if alias already exists
  if (alias) {
    const existing = await Url.findOne({ alias });
    if (existing) {
      return res.status(400).json({ error: 'Alias already taken' });
    }
  }

  const newUrl = new Url({
    originalUrl,
    shortUrl,
    alias: shortUrl,
  });

  await newUrl.save();
  res.json({ shortUrl: `${BASE_URL}/${shortUrl}` });
});

// Route to redirect to original URL
app.get('/:shortUrl', async (req, res) => {
  const { shortUrl } = req.params;
  const url = await Url.findOne({ alias: shortUrl });

  if (url) {
    url.clicks++;
    await url.save();
    return res.redirect(url.originalUrl);
  } else {
    return res.status(404).send('URL not found');
  }
});

app.listen(PORT, () => {
  console.log(`Server running at ${BASE_URL}`);
});

