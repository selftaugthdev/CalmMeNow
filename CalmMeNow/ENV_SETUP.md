# Environment Variables Setup Guide

## 📁 Where to Place Your .env File

Your `.env` file should be placed in the **root directory** of your project, at the same level as your `.xcodeproj` file:

```
CalmMeNow/
├── .env                    ← Place it here (project root)
├── CalmMeNow/
├── CalmMeNow.xcodeproj/
├── README.md
└── .gitignore
```

## 🔧 How to Create Your .env File

### Option 1: Manual Creation (Recommended)

1. **Navigate to your project root** (where `CalmMeNow.xcodeproj` is located)
2. **Create a new file** named exactly `.env` (with the dot)
3. **Add your configuration**:

```bash
# OpenAI Configuration
OPENAI_API_KEY=sk-your_actual_api_key_here
OPENAI_ORGANIZATION_ID=org-your_org_id_here_optional

# API Configuration
OPENAI_MODEL=gpt-3.5-turbo
OPENAI_MAX_TOKENS=150
OPENAI_TEMPERATURE=0.7

# App Configuration
APP_ENV=development
DEBUG_MODE=true
```

### Option 2: Copy from Template

1. **Copy the template**: `cp CalmMeNow/env.template .env`
2. **Edit the file** and replace placeholder values

## 🔑 Getting Your OpenAI API Key

1. Go to [platform.openai.com](https://platform.openai.com)
2. Sign in to your account
3. Navigate to **API Keys** in the left sidebar
4. Click **Create new secret key**
5. Give it a name (e.g., "CalmMeNow Development")
6. Copy the generated key (starts with `sk-`)

## ⚠️ Important Security Notes

- **NEVER commit your `.env` file** to version control
- Your `.gitignore` already excludes `.env` files
- The `.env` file is for **development only**
- In production, use the app's built-in settings

## 🚀 How It Works

The app will automatically:

1. **First try** to read from environment variables (`.env` file)
2. **Fall back** to UserDefaults if no environment variables found
3. **Allow users** to override via the app's AI Settings

## 📱 Testing Your Setup

1. **Create your `.env` file** with your API key
2. **Build and run** your app
3. **Go to Settings** → 🤖 AI Assistant
4. **Check status** - should show "AI Configured" if `.env` is working
5. **Test connection** to verify everything works

## 🔍 Troubleshooting

### "AI Not Configured" Message

- Check that your `.env` file is in the project root
- Verify the file name is exactly `.env` (not `.env.txt`)
- Ensure your API key is correct and starts with `sk-`

### Environment Variables Not Loading

- Make sure you're running from Xcode (not a pre-built app)
- Check that the `.env` file is in the correct location
- Restart Xcode after creating the `.env` file

### Still Having Issues?

- Use the app's built-in AI Settings instead
- The `.env` file is just for development convenience
- UserDefaults will always work as a fallback

## 📋 Example .env File

```bash
# Copy this structure and fill in your values
OPENAI_API_KEY=sk-1234567890abcdef1234567890abcdef1234567890abcdef
OPENAI_ORGANIZATION_ID=org-1234567890abcdef
OPENAI_MODEL=gpt-3.5-turbo
OPENAI_MAX_TOKENS=150
OPENAI_TEMPERATURE=0.7
APP_ENV=development
DEBUG_MODE=true
```

## 🎯 Next Steps

1. Create your `.env` file in the project root
2. Add your OpenAI API key
3. Build and test your app
4. Enjoy AI-powered mental health features! 🧘‍♀️✨
