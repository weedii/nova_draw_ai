# 🎨 Nova Draw AI - Backend

A FastAPI backend that generates step-by-step drawing tutorials for kids using AI. Combines **OpenAI GPT-4o-mini** for kid-friendly instructions and **Google Gemini Nano Banana** for progressive image generation.

## ✨ Features

- 🎯 **One-endpoint solution** - Complete tutorials in a single API call
- 🌍 **Bilingual support** - Instructions in English and German
- 🖼️ **Progressive images** - Each step builds on the previous one
- 📱 **Base64 images** - Ready for frontend consumption (no file management needed)
- ⚡ **Kid-optimized** - Simple language and engaging visuals for ages 6+

## 🚀 Quick Start

### 1. Install Dependencies
```bash
pip install -r requirements.txt
```

### 2. Configure API Keys
Create a `.env` file:
```env
OPENAI_API_KEY=your_openai_api_key_here
GOOGLE_API_KEY=your_google_api_key_here
```

**Get your API keys:**
- OpenAI: https://platform.openai.com/api-keys
- Google: https://aistudio.google.com/app/apikey

### 3. Run the Server
```bash
python main.py
```

Server starts at: `http://localhost:8000`

## 📡 API Usage

### Generate Complete Tutorial
**POST** `/api/generate-tutorial`

**Request:**
```json
{
  "subject": "cat"
}
```

**Response:**
```json
{
  "success": "true",
  "metadata": {
    "subject": "cat",
    "total_steps": 5
  },
  "steps": [
    {
      "step_en": "Draw a round fluffy head in the center...",
      "step_de": "Zeichne einen runden flauschigen Kopf in der Mitte...",
      "step_img": "iVBORw0KGgoAAAANSUhEUgAA..." // base64 PNG
    }
    // ... more steps
  ]
}
```

### Health Check
- **GET** `/` - Welcome message
- **GET** `/health` - Server status

## 🔧 Configuration

### Environment Variables
```env
# Required
OPENAI_API_KEY=sk-...
GOOGLE_API_KEY=AI...

# Optional
HOST=0.0.0.0
PORT=8000
CORS_ORIGINS=*
STORAGE_PATH=storage/drawings
MAX_STEPS=10
MIN_STEPS=3
```

### Customization
- **Step count**: Automatically adjusts (3-10 steps) based on subject complexity
- **Languages**: Currently English + German (easily extendable)
- **Image style**: Black-and-white line drawings optimized for kids

## 📊 Performance

| Subject Complexity | Steps | Generation Time |
|-------------------|-------|-----------------|
| Simple (sun, cloud) | 3-4 | 15-25 seconds |
| Medium (cat, dog) | 5-6 | 25-35 seconds |
| Complex (dragon, castle) | 7-9 | 35-50 seconds |

## 🏗️ Architecture

```
├── main.py              # FastAPI app & routes
├── config.py            # Settings management
├── models.py            # Request/response models
├── utils.py             # Helper functions
├── services/
│   ├── drawing_service.py   # OpenAI integration
│   └── image_service.py     # Google Gemini integration
└── storage/             # Generated images (backup)
```

## 🔄 How It Works

1. **Text Generation**: GPT-4o-mini creates kid-friendly drawing steps
2. **Translation**: Same model translates to German
3. **Image Generation**: Gemini creates progressive images (each builds on previous)
4. **Base64 Encoding**: Images converted to base64 for easy API consumption

## 🛠️ Development

### Interactive API Docs
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

### Testing
```bash
# Test with curl
curl -X POST "http://localhost:8000/api/generate-tutorial" \
  -H "Content-Type: application/json" \
  -d '{"subject": "butterfly"}'

# Test with Python
import requests
response = requests.post(
    "http://localhost:8000/api/generate-tutorial",
    json={"subject": "fish"}
)
print(response.json())
```


## 📱 Frontend Integration

### Flutter Example
```dart
final response = await http.post(
  Uri.parse('http://localhost:8000/api/generate-tutorial'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({'subject': 'cat'}),
);

final tutorial = jsonDecode(response.body);
// tutorial['steps'] contains all step data with base64 images
```

### React Example
```javascript
const response = await fetch('http://localhost:8000/api/generate-tutorial', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ subject: 'dog' })
});

const tutorial = await response.json();
// Display steps with tutorial.steps[i].step_img as base64 images
```

## 🚨 Error Handling

Common errors and solutions:

**API Key Issues:**
```json
{"detail": "OPENAI_API_KEY environment variable is not set"}
```
→ Check your `.env` file has valid API keys

**Image Generation Fails:**
```json
{"detail": "Failed to process image data"}
```
→ Check Google API key and internet connection

**Subject Too Long:**
```json
{"detail": "Subject name too long"}
```
→ Keep subject under 100 characters

## 💰 Cost Estimation

Approximate costs per tutorial:
- **Text generation**: $0.001-0.003 (GPT-4o-mini)
- **Image generation**: $0.01-0.05 per image (Gemini pricing)
- **Total per tutorial**: $0.05-0.40 (for 5-8 steps)

## 🔒 Security Notes

**For Production:**
- Add API authentication
- Configure specific CORS origins
- Implement rate limiting
- Add request validation
- Set up monitoring

## 📞 Support

- Check the interactive docs at `/docs`
- Review error messages in server logs
- Ensure API keys are valid and have sufficient credits

---

**Built for kids learning to draw** 🎨✨
