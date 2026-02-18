import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ai_service.dart';

class AskBottomSheet extends StatefulWidget {
  final String journalContext;

  const AskBottomSheet({super.key, required this.journalContext});

  @override
  State<AskBottomSheet> createState() => _AskBottomSheetState();
}

class _AskBottomSheetState extends State<AskBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = []; // 'role': 'user'/'ai', 'content': '...'
  final AIService _aiService = AIService();
  bool _isLoading = false;
  
  // No ScrollController needed for reverse: true usually, but good for safety

  @override
  void initState() {
    super.initState();
    // Add initial greeting
    _messages.add({
      'role': 'ai',
      'content': 'Hi! I can help you reflect on what you\'ve written. What\'s on your mind?'
    });
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
      _controller.clear();
    });
    
    // With reverse: true, adding to the end puts it at the "bottom" (start of list visually)? 
    // Wait, reverse:true means scrolling starts from bottom. 
    // Item 0 is at the bottom. Item N is at the top.
    // So if I have [Msg1, Msg2], Msg2 should be at Index 0.
    // So I need to reverse the list in the builder.

    try {
      final response = await _aiService.chat(text, widget.journalContext);
      if (mounted) {
        setState(() {
          _messages.add({'role': 'ai', 'content': response});
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({'role': 'ai', 'content': 'Sorry, I encountered an error. Please try again.'});
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine strict theme colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.grey[100]!;
    final textColor = isDark ? Colors.white : Colors.black87;
    final primaryColor = Theme.of(context).primaryColor;

    // Prepare list for reverse display (Newest at index 0)
    final reversedMessages = List<Map<String, String>>.from(_messages.reversed);

    return Container(
      // Increase height to 85% for better visibility
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle Bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Ask AI Assistant',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: Colors.grey,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Chat Area (Reversed)
          Expanded(
            child: ListView.builder(
              reverse: true, // Key for chat responsiveness
              padding: const EdgeInsets.all(20),
              // If loading, add 1 item at the beginning (bottom)
              itemCount: reversedMessages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                // If loading, show loading bubble at index 0
                if (_isLoading && index == 0) {
                   return _buildLoadingBubble(isDark, primaryColor);
                }
                
                // Adjust index if loading is present
                final msgIndex = _isLoading ? index - 1 : index;
                final msg = reversedMessages[msgIndex];
                
                final isUser = msg['role'] == 'user';
                return _buildMessageBubble(
                  msg['content']!, 
                  isUser, 
                  isDark, 
                  primaryColor,
                  isUser ? primaryColor : cardColor,
                  isUser ? Colors.white : textColor,
                );
              },
            ),
          ),

          // Input Area
          Container(
            padding: EdgeInsets.only(
              left: 20, 
              right: 20, 
              top: 16, 
              // IMPORTANT: Add padding for keyboard AND system nav bar
              bottom: (MediaQuery.of(context).viewInsets.bottom > 0 
                  ? MediaQuery.of(context).viewInsets.bottom 
                  : MediaQuery.of(context).padding.bottom) + 20
            ),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end, // Align to bottom for multiline
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(color: textColor),
                    maxLines: 5, // Allow multiline
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Ask a question...',
                      hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.6)),
                      filled: true,
                      fillColor: cardColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  margin: const EdgeInsets.only(bottom: 4), // Align with input
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_upward, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
      String text, bool isUser, bool isDark, Color primary, Color bubbleColor, Color textColor) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.lato(
            fontSize: 16,
            color: textColor,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingBubble(bool isDark, Color primary) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: SizedBox(
          width: 40,
          height: 20,
           child: Center(
             child: CircularProgressIndicator(strokeWidth: 2, color: primary),
           ),
        ),
      ),
    );
  }
}
