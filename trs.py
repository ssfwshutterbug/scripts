from google.cloud import translate_v2 as translate

# Initialize the client
client = translate.Client()

# Text to be translated
text = 'Hello, how are you?'

# Target language
target_language = 'fr'  # French

# Translate the text
translation = client.translate(text, target_language=target_language)

# Extract translated text
translated_text = translation['translatedText']

print('Original text:', text)
print('Translated text:', translated_text)
