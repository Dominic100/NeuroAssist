import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';

class TTSSTTHome extends StatefulWidget {
  @override
  _TTSSTTHomeState createState() => _TTSSTTHomeState();
}

class _TTSSTTHomeState extends State<TTSSTTHome> with WidgetsBindingObserver {
  FlutterTts flutterTts = FlutterTts();
  stt.SpeechToText speechToText = stt.SpeechToText();
  AudioPlayer audioPlayer = AudioPlayer();

  // Camera and text recognition variables
  List<CameraDescription>? cameras;
  CameraController? cameraController;
  TextRecognizer? textRecognizer;
  bool isImageProcessing = false;
  bool isCameraActive = false;
  String lastRecognizedImageText = "";

  TextEditingController textController = TextEditingController();
  String recognizedText = "";
  bool isListening = false;
  bool isSpeaking = false;
  bool isProcessing = false;
  
  // User data
  String? userEmail;
  bool isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize in sequence to ensure proper initialization
    _loadUserData();
    _initTtsAndRecognizer();
  }
  
  // Load user data
  Future<void> _loadUserData() async {
    setState(() {
      isLoadingUser = true;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          userEmail = user.email;
          isLoadingUser = false;
        });
      } else {
        setState(() {
          userEmail = 'Guest User';
          isLoadingUser = false;
        });
      }
    } catch (e) {
      print('Error getting user data: $e');
      setState(() {
        userEmail = 'Guest User';
        isLoadingUser = false;
      });
    }
  }

  Future<void> _initTtsAndRecognizer() async {
    await _initTts();  // Wait for TTS to initialize
    _initTextRecognizer();
    _checkCameraAvailable();
  }

  // Check if camera is available
  Future<void> _checkCameraAvailable() async {
    try {
      cameras = await availableCameras();
    } catch (e) {
      print("Error checking cameras: $e");
    }
  }

  // Initialize text recognizer
  Future<void> _initTextRecognizer() async {
    // Use the script parameter for better recognition
    textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  }

  // Initialize camera
  Future<void> _initializeCamera() async {
    // Request camera permission
    var status = await Permission.camera.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera permission is required for this feature')),
      );
      return;
    }

    try {
      // Ensure cameras are loaded
      if (cameras == null) {
        await _checkCameraAvailable();
      }
      
      if (cameras == null || cameras!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No cameras available')),
        );
        return;
      }

      cameraController = CameraController(
        cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid 
            ? ImageFormatGroup.yuv420 
            : ImageFormatGroup.bgra8888,
      );

      await cameraController!.initialize();
      if (!mounted) return;

      // Start image stream for real-time processing
      await cameraController!.startImageStream(_processImageStream);

      setState(() {
        isCameraActive = true;
      });
    } catch (e) {
      print("Camera initialization error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing camera: $e')),
      );
    }
  }

  // Process image stream for text recognition with throttling
  void _processImageStream(CameraImage image) {
    // Only process every 10th frame to reduce processing load
    if (isImageProcessing || textRecognizer == null) return;
    
    isImageProcessing = true;
    
    // Convert and process the image on a background isolate or thread
    Future.microtask(() async {
      try {
        final inputImage = _convertCameraImageToInputImage(image);
        if (inputImage == null) return;
        
        final RecognizedText recognizedText = await textRecognizer!.processImage(inputImage);
        
        if (recognizedText.text.isNotEmpty && 
            recognizedText.text.length > 5 &&  // Only process text with sufficient length
            recognizedText.text != lastRecognizedImageText) {
          
          print("New text recognized: ${recognizedText.text}");
          
          // Update UI first
          if (mounted) {
            setState(() {
              lastRecognizedImageText = recognizedText.text;
            });
          }
          
          // Only speak if not already speaking and app is still mounted
          if (!isSpeaking && mounted) {
            await speakText(recognizedText.text);
          }
        }
      } catch (e) {
        print("Error processing image: $e");
      } finally {
        // Add delay to throttle processing
        await Future.delayed(Duration(milliseconds: 1000));
        isImageProcessing = false;
      }
    });
  }

  // Convert CameraImage to InputImage
  InputImage? _convertCameraImageToInputImage(CameraImage image) {
    try {
      final camera = cameras![0];
      
      // For Android devices
      if (Platform.isAndroid) {
        // Handle Android YUV format
        final WriteBuffer allBytes = WriteBuffer();
        for (final Plane plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        final bytes = allBytes.done().buffer.asUint8List();

        // Get rotation
        final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation) ?? 
                        InputImageRotation.rotation0deg;
        
        // Get format
        final format = InputImageFormat.yuv420;
        
        final inputImageData = InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes[0].bytesPerRow,
        );

        return InputImage.fromBytes(
          bytes: bytes,
          metadata: inputImageData,
        );
      } 
      // For iOS devices
      else if (Platform.isIOS) {
        // For iOS, we can use just the first plane (which is typically BGRA)
        final bytes = image.planes[0].bytes;
        final format = InputImageFormat.bgra8888;

        final inputImageData = InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg, // iOS usually doesn't need rotation
          format: format,
          bytesPerRow: image.planes[0].bytesPerRow,
        );

        return InputImage.fromBytes(
          bytes: bytes,
          metadata: inputImageData,
        );
      }
      
      return null;
    } catch (e) {
      print("Error converting image: $e");
      return null;
    }
  }

  // Toggle camera on/off
  void _toggleCamera() async {
    if (isCameraActive) {
      // Stop camera
      await cameraController?.stopImageStream();
      await cameraController?.dispose();
      setState(() {
        isCameraActive = false;
      });
    } else {
      // Start camera
      await _initializeCamera();
    }
  }

  // Initialize TTS with language and event listeners
  Future<void> _initTts() async {
    await flutterTts.setLanguage("en-US");
    
    flutterTts.setStartHandler(() {
      setState(() {
        isSpeaking = true;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        isSpeaking = false;
      });
    });

    flutterTts.setErrorHandler((error) {
      setState(() {
        isSpeaking = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('TTS Error: $error')),
      );
    });
  }

  // Modified speakText function with better error handling
  Future<void> speakText(String text) async {
    if (text.trim().isEmpty) {
      print("Text is empty, not speaking");
      return;
    }
    
    if (isSpeaking) {
      print("Already speaking, stopping current speech");
      await flutterTts.stop();
      setState(() {
        isSpeaking = false;
      });
      return;
    }
    
    try {
      print("Speaking text: '$text'");
      
      // Set these before speaking to ensure state is correct
      setState(() {
        isSpeaking = true;
      });
      
      var result = await flutterTts.speak(text);
      print("TTS speak result: $result");
      
      // If speak fails, reset the speaking state
      if (result != 1) {
        setState(() {
          isSpeaking = false;
        });
      }
    } catch (e) {
      print("TTS Error: $e");
      setState(() {
        isSpeaking = false;
      });
    }
  }

  // Function to handle file upload for TTS
  Future<void> pickTextFile() async {
    try {
      setState(() {
        isProcessing = true;
      });
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        setState(() {
          textController.text = content;
          isProcessing = false;
        });
        await speakText(content);
      } else {
        setState(() {
          isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading text file: $e')),
      );
    }
  }

  // Function to start/stop speech recognition
  Future<void> toggleRecording() async {
    if (!isListening) {
      // First check current permission status
      var status = await Permission.microphone.status;
      
      if (status.isDenied) {
        // Request permission if currently denied
        status = await Permission.microphone.request();
      }
      
      if (status.isPermanentlyDenied) {
        // Open app settings if permanently denied
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Microphone permission is permanently denied. Please enable it in app settings.'),
            action: SnackBarAction(
              label: 'Open Settings',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        return;
      }
      
      if (status.isGranted) {
        // Permission is granted, proceed with speech recognition
        setState(() {
          isProcessing = true;
        });
        
        bool available = await speechToText.initialize(
          onError: (error) {
            print("STT Error: $error");
            setState(() {
              isListening = false;
              isProcessing = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Speech recognition error: ${error.errorMsg}')),
            );
          },
          debugLogging: true,
        );

        if (available) {
          setState(() {
            isListening = true;
            isProcessing = false;
          });
          try {
            await speechToText.listen(
              onResult: (result) {
                setState(() {
                  // Append new text instead of replacing it
                  if (result.recognizedWords.isNotEmpty) {
                    recognizedText = recognizedText + " " + result.recognizedWords;
                  }
                });
              },
              // Use the newer parameters
              listenOptions: stt.SpeechListenOptions(
                autoPunctuation: true,       // Enable automatic punctuation
                listenMode: stt.ListenMode.dictation, // Use dictation mode for continuous listening
                cancelOnError: false,        // Don't cancel on errors
                partialResults: true,        // Get results as they come in
              ),
            );
            print("Listening started successfully");
          } catch (e) {
            print("Error starting listening: $e");
            setState(() {
              isListening = false;
              isProcessing = false;
            });
          }
        } else {
          print("Speech recognition not available");
          setState(() {
            isProcessing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Speech recognition is not available on this device')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Microphone permission is required for speech recognition')),
        );
      }
    } else {
      setState(() => isListening = false);
      speechToText.stop();
      print("Listening stopped");
    }
  }

  // Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }
    
    if (state == AppLifecycleState.inactive) {
      // Free up resources when app is inactive
      cameraController?.dispose();
      isCameraActive = false;
    } else if (state == AppLifecycleState.resumed) {
      // Reinitialize camera if it was active when app went to background
      if (isCameraActive) {
        _initializeCamera();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "Text & Speech Tools",
          style: TextStyle(
            color: Colors.greenAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.greenAccent),
        actions: [
          // User email display
          if (!isLoadingUser)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  userEmail ?? 'Guest User',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: isProcessing 
          ? Center(child: CircularProgressIndicator(color: Colors.greenAccent))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Live Image Recognition Section
                    Text(
                      "Live Camera Text Recognition",
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent,
                      )
                    ),
                    SizedBox(height: 12),
                    
                    // Camera toggle button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _toggleCamera,
                        icon: Icon(isCameraActive ? Icons.stop : Icons.camera_alt),
                        label: Text(isCameraActive ? "Stop Camera" : "Start Camera"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCameraActive ? Colors.redAccent : Colors.grey[900],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isCameraActive ? Colors.redAccent : Colors.greenAccent.withOpacity(0.5),
                            ),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Camera preview
                    if (isCameraActive && cameraController != null && cameraController!.value.isInitialized)
                      Container(
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9.0),
                          child: CameraPreview(cameraController!),
                        ),
                      ),
                    
                    if (isCameraActive && lastRecognizedImageText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Last Recognized Text:", 
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.greenAccent,
                              )
                            ),
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.all(12),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                              ),
                              child: Text(
                                lastRecognizedImageText,
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    Divider(
                      height: 40,
                      color: Colors.greenAccent.withOpacity(0.3),
                      thickness: 1,
                    ),

                    // Text-to-Speech Section
                    Text(
                      "Text-to-Speech",
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent,
                      )
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: textController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Enter text to speak...",
                        hintStyle: TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.greenAccent),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.greenAccent.withOpacity(0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.greenAccent),
                        ),
                        filled: true,
                        fillColor: Colors.grey[900],
                      ),
                      maxLines: 5,
                      minLines: 3,
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => speakText(textController.text),
                            icon: Icon(isSpeaking ? Icons.stop : Icons.volume_up),
                            label: Text(isSpeaking ? "Stop" : "Speak"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSpeaking ? Colors.redAccent : Colors.grey[900],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: isSpeaking ? Colors.redAccent : Colors.greenAccent.withOpacity(0.5),
                                ),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: pickTextFile,
                            icon: Icon(Icons.upload_file),
                            label: Text("Upload Text"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[900],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: Colors.greenAccent.withOpacity(0.5)),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: textController.text.isNotEmpty
                              ? () => textController.clear()
                              : null,
                          icon: Icon(Icons.clear, color: Colors.redAccent),
                          label: Text("Clear", style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                    
                    Divider(
                      height: 40,
                      color: Colors.greenAccent.withOpacity(0.3),
                      thickness: 1,
                    ),
                    
                    // Speech-to-Text Section
                    Text(
                      "Speech-to-Text", 
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent,
                      )
                    ),
                    SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: toggleRecording,
                        icon: Icon(isListening ? Icons.stop : Icons.mic),
                        label: Text(isListening ? "Stop Recording" : "Start Recording"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isListening ? Colors.redAccent : Colors.grey[900],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isListening ? Colors.redAccent : Colors.greenAccent.withOpacity(0.5),
                            ),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          "Recognized Text:", 
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold,
                            color: Colors.greenAccent,
                          )
                        ),
                        Spacer(),
                        TextButton.icon(
                          onPressed: recognizedText.isNotEmpty
                              ? () {
                                  setState(() {
                                    textController.text = recognizedText;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Text copied to input field'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              : null,
                          icon: Icon(Icons.copy, color: Colors.greenAccent),
                          label: Text("Use as input", style: TextStyle(color: Colors.greenAccent)),
                          style: ButtonStyle(
                            overlayColor: MaterialStateProperty.all(Colors.greenAccent.withOpacity(0.1)),
                          ),
                        ),
                      ],
                    ),
                    
                    Container(
                      padding: EdgeInsets.all(12),
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          recognizedText,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    
                    if (isListening)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.mic, color: Colors.redAccent),
                              SizedBox(width: 8),
                              Text(
                                "Listening...", 
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                )
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    // Release resources when the screen is disposed
    WidgetsBinding.instance.removeObserver(this);
    textRecognizer?.close();
    cameraController?.dispose();
    flutterTts.stop();
    speechToText.cancel();
    audioPlayer.dispose();
    textController.dispose();
    super.dispose();
  }
}