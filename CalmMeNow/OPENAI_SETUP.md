# OpenAI Integration Setup Guide

## 🚀 Getting Started

This guide will help you set up OpenAI GPT-3.5 integration in your CalmMeNow app.

## 📋 Prerequisites

1. **OpenAI Account**: You need an OpenAI account at [platform.openai.com](https://platform.openai.com)
2. **API Key**: Generate an API key from your OpenAI dashboard
3. **iOS Development Environment**: Xcode 14+ with iOS 16+ deployment target

## 🔑 Step 1: Get Your OpenAI API Key

1. Go to [platform.openai.com](https://platform.openai.com)
2. Sign in or create an account
3. Navigate to **API Keys** in the left sidebar
4. Click **Create new secret key**
5. Give it a name (e.g., "CalmMeNow App")
6. Copy the generated key (you won't see it again!)

## ⚙️ Step 2: Configure the App

1. **Open the App**: Launch CalmMeNow in Xcode
2. **Go to Settings**: Navigate to the Settings tab
3. **AI Assistant Section**: Tap on "🤖 AI Assistant"
4. **Enter API Key**: Paste your OpenAI API key
5. **Test Connection**: Tap "Test Connection" to verify setup
6. **Save**: Tap "Save Configuration"

## 🔒 Security Features

- **Local Storage**: API keys are stored securely on your device
- **No Cloud Sync**: Keys are never uploaded to external servers
- **User Control**: Users can clear their configuration at any time
- **Fallback Mode**: App works without AI if not configured

## 🤖 AI Features Available

Once configured, your app will have:

### 1. **Personalized Calming Advice**

- Emotion-based guidance
- Intensity-specific recommendations
- Immediate relief techniques

### 2. **Custom Breathing Instructions**

- Emotion-tailored breathing patterns
- Specific count instructions
- Gentle, accessible guidance

### 3. **Therapeutic Journaling Prompts**

- Context-aware prompts
- Self-compassion focused
- Non-judgmental approach

### 4. **Emergency Calm Strategies**

- Crisis-specific guidance
- Immediate safety techniques
- Professional help recommendations

## 🎯 Usage Examples

### Emergency Companion

- Users can describe their feelings
- AI provides personalized responses
- Quick emotion selection for instant help

### Breathing Exercises

- AI generates custom breathing patterns
- Adapts to user's emotional state
- Provides gentle, supportive guidance

### Journaling

- Context-aware prompts
- Emotional state consideration
- Therapeutic approach

## 🛠️ Technical Details

### API Configuration

- **Model**: GPT-3.5-turbo
- **Max Tokens**: 150 (optimized for quick responses)
- **Temperature**: 0.7 (balanced creativity and consistency)

### Error Handling

- Network connectivity issues
- API rate limiting
- Invalid API keys
- Fallback responses when AI is unavailable

### Performance

- Async/await for non-blocking UI
- Response caching for better UX
- Loading states and progress indicators

## 🔧 Troubleshooting

### Common Issues

1. **"AI Not Configured" Message**

   - Go to Settings → AI Assistant
   - Enter your API key
   - Test the connection

2. **Connection Test Fails**

   - Check your internet connection
   - Verify your API key is correct
   - Ensure you have OpenAI API credits

3. **Slow Responses**
   - Check your internet speed
   - OpenAI API response times vary
   - Consider upgrading to GPT-4 for faster responses

### Support

If you encounter issues:

1. Check your OpenAI account status
2. Verify API key permissions
3. Check your API usage and credits
4. Test with a simple message first

## 💡 Best Practices

1. **Start Simple**: Test with basic emotions first
2. **Monitor Usage**: Keep track of your OpenAI API usage
3. **User Privacy**: Remind users that conversations are processed by AI
4. **Fallback Plans**: Always have non-AI alternatives available

## 🔮 Future Enhancements

Potential improvements:

- Voice interaction with AI
- Personalized learning from user patterns
- Integration with health apps
- Multi-language support
- Offline AI capabilities

## 📱 Testing Your Integration

1. **Configure API Key**: Follow the setup steps above
2. **Test Emergency Companion**: Try the AI-enhanced emergency view
3. **Test Different Emotions**: Try various emotional states
4. **Verify Responses**: Ensure AI responses are appropriate and helpful

## 🎉 You're All Set!

Once configured, your CalmMeNow app will provide:

- **Personalized** mental health support
- **Immediate** calming guidance
- **Adaptive** breathing exercises
- **Contextual** journaling prompts

The AI will enhance your app's ability to help users in crisis while maintaining the gentle, supportive tone that makes CalmMeNow special.

---

**Need Help?** Check the OpenAI documentation or contact support if you encounter technical issues.
