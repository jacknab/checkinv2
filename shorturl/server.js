const express = require('express');
const mongoose = require('mongoose');
const shortid = require('shortid');
const cors = require('cors');
const app = express();
const PORT = 5000;
const BASE_URL = 'https://review.poolets.com';

// Connect to MongoDB
mongoose.connect('mongodb://admin:1825Logan305%21@127.0.0.1:27017/urlShortener?authSource=admin', {
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

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: false }));

// Route to create short URL via API
app.post('/api/shorten', async (req, res) => {
  const { originalUrl, alias } = req.body;

  if (!originalUrl || !/^https?:\/\//i.test(originalUrl)) {
    return res.status(400).json({ error: 'Invalid URL' });
  }

  let shortUrl = alias ? alias : shortid.generate();

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

  res.json({
    shortUrl: `${BASE_URL}/${shortUrl}`,
    originalUrl: originalUrl,
  });
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
