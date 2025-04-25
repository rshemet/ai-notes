import 'package:fllama/fllama.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io'; // Import for Directory

class LLMModel {
  String latestResult = "";
  String modelPath = "";

  LLMModel._();

  static Future<LLMModel> create() async {
    final instance = LLMModel._();
    await instance._initialize();
    return instance;
  }

  Future<void> _initialize() async {
    try {
      modelPath = await getModelPath();
    } catch (e) {
      print("Failed to initialize model: $e");
      rethrow;
    }
  }

  OpenAiRequest getRequest(String systemPrompt, String userMessage) {
    return OpenAiRequest(
      maxTokens: 256,
      messages: [
        Message(Role.system, systemPrompt),
        Message(Role.user, userMessage),
      ],
      numGpuLayers: 99, /* this seems to have no adverse effects in environments w/o GPU support, ex. Android and web */
      modelPath: modelPath,
      mmprojPath: '', // multimodal only
      frequencyPenalty: 0.0,
      presencePenalty: 1.1,
      topP: 1.0,
      contextSize: 2048,
      temperature: 0.1,
    );
  }

  Future<String> getModelPath() async {
    final directoryPath = await getApplicationDocumentsDirectory();
    final modelFileName = 'local-models/SmolLM-135.gguf'; // Your model file name
    // final modelFileName = 'local-models/qwen2.5-1.5b-instruct-q8_0.gguf';
    final fullModelPath = '${directoryPath.path}/$modelFileName';
    
    final modelFile = File(fullModelPath);
    final exists = await modelFile.exists();
    if (!exists) {
      throw Exception('Model file not found at path: $fullModelPath');
    } 
    print("Model file found at path: $fullModelPath");
    return fullModelPath;
  }

  Future<int> summarize(String noteText, Function(String) onPartialCallback,Function(String) onCompleteCallback) async {
    return await fllamaChat(getRequest(
      'You are a note summarizer. The user will provide you with a note and you will summarize it. You will respond ONLY with a four-word summary for a note title.',
      noteText,
    ), (String response, String openaiResponseJsonString, bool done) {
      onPartialCallback(response);
      if (done) {
        onCompleteCallback(response);
      }
    });
  }
}