import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String baseUrl =
    'https://student-performance-prediction-system-production-a040.up.railway.app';

class QuizQuestion {
  final int id;
  final String displayText;
  final String inputType;
  final List<String> options;
  final List<String> optionValues;

  QuizQuestion({
    required this.id,
    required this.displayText,
    required this.inputType,
    required this.options,
    required this.optionValues,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    List<String> labels = [];
    List<String> values = [];

    if (rawOptions != null && rawOptions is List) {
      for (var o in rawOptions) {
        if (o is Map) {
          final display = o['display']?.toString() ?? '';
          final value = o['value']?.toString() ?? '';
          if (display != 'Other') {
            labels.add(display);
            values.add(value);
          }
        } else {
          labels.add(o.toString());
          values.add(o.toString());
        }
      }
    }

    return QuizQuestion(
      id: int.tryParse(json['id'].toString()) ?? 0,
      displayText: json['display_text']?.toString() ?? '',
      inputType: json['input_type']?.toString() ?? 'select',
      options: labels,
      optionValues: values,
    );
  }
}

class Quiz1 extends StatefulWidget {
  final String token;

  const Quiz1({super.key, required this.token, String title = ''});

  @override
  State<Quiz1> createState() => _Quiz1State();
}

class _Quiz1State extends State<Quiz1> {
  List<QuizQuestion> questions = [];
  int questionIndex = 0;
  int currentBatch = 1;
  String? quizSessionId;

  int totalAnswered = 0;
  static const int totalQuestions = 30;

  final Map<int, String> answers = {};

  bool loading = true;
  bool submitting = false;
  Map<String, dynamic>? result;
  String? errorMessage;

  String? selfPrediction;
  bool showSelfPredictionQuestion = false;
  final TextEditingController _predictionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    startBatch(1);
  }

  @override
  void dispose() {
    _predictionController.dispose();
    super.dispose();
  }

  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer ${widget.token}',
  };

  Future<void> startBatch(int batch) async {
    setState(() {
      loading = true;
      errorMessage = null;
      questions = [];
      questionIndex = 0;
    });

    try {
      final startRes = await http.post(
        Uri.parse('$baseUrl/api/quiz/start/$batch'),
        headers: _authHeaders,
      );

      if (startRes.statusCode != 200) {
        setState(() {
          loading = false;
          errorMessage = 'Failed to start quiz: ${startRes.body}';
        });
        return;
      }

      final startData = jsonDecode(startRes.body);
      quizSessionId = startData["quiz_session_id"].toString();
      currentBatch = batch;

      final qRes = await http.get(
        Uri.parse(
            '$baseUrl/api/quiz/$batch/questions?quiz_session_id=$quizSessionId'),
        headers: _authHeaders,
      );

      if (qRes.statusCode == 403) {
        setState(() {
          loading = false;
          errorMessage = 'Session expired. Please try again.';
        });
        return;
      }

      if (qRes.statusCode != 200) {
        setState(() {
          loading = false;
          errorMessage = 'Failed to load questions: ${qRes.body}';
        });
        return;
      }

      final qData = jsonDecode(qRes.body);
      final List<QuizQuestion> loaded = (qData['questions'] as List)
          .map((q) => QuizQuestion.fromJson(q))
          .toList();

      setState(() {
        questions = loaded;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> submitBatch() async {
    setState(() {
      submitting = true;
      errorMessage = null;
    });

    try {
      final answersList = questions
          .map((q) => {
        'question_id': q.id,
        'answer': answers[q.id] ?? '',
      })
          .toList();

      final body = jsonEncode({
        'quiz_session_id': quizSessionId,
        'batch': currentBatch,
        'answers': answersList,
        'self_prediction': selfPrediction,
      });

      final res = await http.post(
        Uri.parse('$baseUrl/api/quiz/save-answers'),
        headers: _authHeaders,
        body: body,
      );

      if (res.statusCode != 200) {
        setState(() {
          submitting = false;
          errorMessage = 'Server error (${res.statusCode}): ${res.body}';
        });
        return;
      }

      final data = jsonDecode(res.body);

      if (data['status'] == 'next_batch') {
        setState(() {
          totalAnswered += questions.length;
          submitting = false;
          showSelfPredictionQuestion = false;
        });
        await startBatch(
            int.tryParse(data['next_batch'].toString()) ?? (currentBatch + 1));
      } else if (data['status'] == 'completed') {
        setState(() {
          totalAnswered = totalQuestions;
          submitting = false;
          result = data;
        });
      }
    } catch (e) {
      setState(() {
        submitting = false;
        errorMessage = 'Something went wrong: $e';
      });
    }
  }

  void next() {
    final q = questions[questionIndex];
    if (!answers.containsKey(q.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please select an answer"),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (questionIndex < questions.length - 1) {
      setState(() => questionIndex++);
    } else {
      final isLastBatch =
          (totalAnswered + questions.length) >= totalQuestions;
      if (isLastBatch && !showSelfPredictionQuestion) {
        setState(() => showSelfPredictionQuestion = true);
      } else {
        submitBatch();
      }
    }
  }

  void prev() {
    if (showSelfPredictionQuestion) {
      setState(() => showSelfPredictionQuestion = false);
    } else if (questionIndex > 0) {
      setState(() => questionIndex--);
    }
  }

  void reset() => setState(() {
    questionIndex = 0;
    answers.clear();
    result = null;
    errorMessage = null;
    questions = [];
    totalAnswered = 0;
    selfPrediction = null;
    showSelfPredictionQuestion = false;
    _predictionController.clear();
  });

  static const _gradientColors = [
    Color(0xFF6C63FF),
    Color(0xFF8B5CF6),
    Color(0xFF4F46E5),
  ];

  double _getSliderMax(String questionText) {
    final text = questionText.toLowerCase();
    if (text.contains('1 to 10') ||
        text.contains('1-10') ||
        text.contains('out of 10') ||
        text.contains('scale of 10') ||
        text.contains('from 1 to 10') ||
        text.contains('rate') && text.contains('10')) {
      return 10;
    }
    if (text.contains('1 to 5') ||
        text.contains('1-5') ||
        text.contains('out of 5') ||
        text.contains('scale of 5')) {
      return 5;
    }
    if (text.contains('100') ||
        text.contains('percentage') ||
        text.contains('%')) {
      return 100;
    }
    return 20;
  }

  Widget _buildSliderInput(QuizQuestion q) {
    final double maxVal = _getSliderMax(q.displayText);
    final double minVal = 1;
    final currentVal = double.tryParse(answers[q.id] ?? '') ??
        ((maxVal + minVal) / 2).roundToDouble();

    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${currentVal.toInt()}',
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'from ${minVal.toInt()} to ${maxVal.toInt()}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 24),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white.withOpacity(0.3),
                thumbColor: Colors.white,
                overlayColor: Colors.white.withOpacity(0.15),
                trackHeight: 6,
                thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 14),
                overlayShape:
                const RoundSliderOverlayShape(overlayRadius: 26),
              ),
              child: Slider(
                min: minVal,
                max: maxVal,
                divisions: (maxVal - minVal).toInt(),
                value: currentVal.clamp(minVal, maxVal),
                onChanged: (val) {
                  setState(() => answers[q.id] = val.toInt().toString());
                },
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${minVal.toInt()}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${maxVal.toInt()}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getOptionIcon(String display) {
    final d = display.toLowerCase();
    if (d.contains('never') || d.contains('no') || d.contains('none'))
      return Icons.remove_circle_outline;
    if (d.contains('strongly disagree')) return Icons.thumb_down;
    if (d.contains('rarely') || d.contains('disagree'))
      return Icons.thumb_down_outlined;
    if (d.contains('sometimes') || d.contains('neutral'))
      return Icons.horizontal_rule;
    if (d.contains('strongly agree')) return Icons.star;
    if (d.contains('often') || d.contains('agree') || d.contains('yes'))
      return Icons.thumb_up_outlined;
    if (d.contains('always')) return Icons.star_outline;
    if (d.contains('male')) return Icons.male;
    if (d.contains('female')) return Icons.female;
    return Icons.radio_button_unchecked;
  }

  Widget _buildOptionCard(String display, String value, QuizQuestion q) {
    final selected = answers[q.id] == value;
    final icon = _getOptionIcon(display);
    return GestureDetector(
      onTap: () => setState(() => answers[q.id] = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.white : Colors.white.withOpacity(0.3),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
            BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ]
              : [],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF6C63FF).withOpacity(0.1)
                  : Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                color: selected ? const Color(0xFF6C63FF) : Colors.white,
                size: 24),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              display,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? const Color(0xFF4F46E5) : Colors.white,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? const Color(0xFF6C63FF)
                  : Colors.transparent,
              border: Border.all(
                color: selected
                    ? const Color(0xFF6C63FF)
                    : Colors.white.withOpacity(0.6),
                width: 2,
              ),
            ),
            child: selected
                ? const Icon(Icons.check, color: Colors.white, size: 12)
                : null,
          ),
        ]),
      ),
    );
  }

  Widget _buildListOption(String display, String value, QuizQuestion q) {
    final selected = answers[q.id] == value;
    return GestureDetector(
      onTap: () => setState(() => answers[q.id] = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.white : Colors.white.withOpacity(0.3),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
            BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ]
              : [],
        ),
        child: Row(children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? const Color(0xFF6C63FF)
                  : Colors.transparent,
              border: Border.all(
                color: selected
                    ? const Color(0xFF6C63FF)
                    : Colors.white.withOpacity(0.7),
                width: 2,
              ),
            ),
            child: selected
                ? const Icon(Icons.check, color: Colors.white, size: 13)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              display,
              style: TextStyle(
                fontSize: 15,
                color: selected ? const Color(0xFF4F46E5) : Colors.white,
                fontWeight:
                selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildSelfPredictionQuestion() {
    final options = [
      {'label': 'Excellent', 'icon': '🏆'},
      {'label': 'Good', 'icon': '😊'},
      {'label': 'Pass', 'icon': '🎉'},
      {'label': 'Fail', 'icon': '📚'},
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: _gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: () =>
                        setState(() => showSelfPredictionQuestion = false),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 16),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$totalQuestions/$totalQuestions',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(children: [
                  const Text(
                    'Student Performance Quiz',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'One last question before we submit!',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.8),
                        height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ]),
              ),
              const SizedBox(height: 20),

              // Progress bar (100%)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: 1.0,
                    minHeight: 6,
                    backgroundColor: Colors.white.withOpacity(0.25),
                    valueColor:
                    const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border:
                    Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'What your grade last year?',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1.5),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enter your percentage manually',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.7)),
                        ),
                      ]),
                ),
              ),
              const SizedBox(height: 16),

              // Manual Input Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _predictionController,
                  keyboardType: TextInputType.text,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: InputDecoration(
                    hintText: 'e.g. 95%',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.15),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.white, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  ),
                  onChanged: (val) => selfPrediction = val,
                ),
              ),
              const Spacer(),

              // Error message
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(errorMessage!,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12)),
                  ),
                ),

              // Submit Button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(children: [
                  GestureDetector(
                    onTap: () =>
                        setState(() => showSelfPredictionQuestion = false),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.4)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: submitting
                          ? null
                          : () {
                        if (selfPrediction == null || selfPrediction!.isEmpty) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            SnackBar(
                              content: const Text(
                                  "Please enter your grade"),
                              backgroundColor: Colors.red.shade400,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(12)),
                            ),
                          );
                          return;
                        }
                        submitBatch();
                      },
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: Center(
                          child: submitting
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF6C63FF)),
                          )
                              : const Row(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                Text('Submit',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4F46E5))),
                                SizedBox(width: 6),
                                Icon(Icons.check_circle_outline,
                                    color: Color(0xFF4F46E5), size: 18),
                              ]),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: _gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
              child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }

    if (errorMessage != null && questions.isEmpty) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: _gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline,
                    size: 56, color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style:
                  const TextStyle(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      loading = true;
                      errorMessage = null;
                    });
                    startBatch(1);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6C63FF),
                  ),
                  child: const Text('Retry'),
                ),
              ]),
            ),
          ),
        ),
      );
    }

    if (result != null) return _buildResult();

    if (showSelfPredictionQuestion) return _buildSelfPredictionQuestion();

    final q = questions[questionIndex];
    final useGrid = q.options.length <= 6;
    final isNumber = q.inputType == 'number';
    final progress =
        (totalAnswered + questionIndex + 1) / totalQuestions;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: _gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(
                        context, totalAnswered / totalQuestions),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 16),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${totalAnswered + questionIndex + 1}/$totalQuestions',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(children: [
                  const Text(
                    'Student Performance Quiz',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Answer the questions below to help us assess your academic performance',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.8),
                        height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withOpacity(0.25),
                    valueColor:
                    const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border:
                    Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q.displayText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isNumber
                              ? 'Slide to select a number'
                              : 'Choose what suits you',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.7)),
                        ),
                      ]),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: isNumber
                      ? _buildSliderInput(q)
                      : useGrid
                      ? GridView.builder(
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: q.options.length,
                    itemBuilder: (_, i) => _buildOptionCard(
                        q.options[i], q.optionValues[i], q),
                  )
                      : ListView.builder(
                    itemCount: q.options.length,
                    itemBuilder: (_, i) => Padding(
                      padding:
                      const EdgeInsets.only(bottom: 10),
                      child: _buildListOption(
                          q.options[i], q.optionValues[i], q),
                    ),
                  ),
                ),
              ),
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(errorMessage!,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12)),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(children: [
                  if (questionIndex > 0) ...[
                    GestureDetector(
                      onTap: prev,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.4)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: GestureDetector(
                      onTap: submitting ? null : next,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Center(
                          child: submitting
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF6C63FF)),
                          )
                              : Row(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                Text(
                                  questionIndex ==
                                      questions.length - 1
                                      ? 'Next'
                                      : 'Next',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4F46E5),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.arrow_forward,
                                    color: Color(0xFF4F46E5),
                                    size: 18),
                              ]),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    final prediction =
    (result!['prediction'] ?? '').toString().toLowerCase();
    final recommendations =
    result!['recommendations'] as List<dynamic>?;

    String icon, title, subtitle;
    switch (prediction) {
      case 'excellent':
        icon = '🏆';
        title = 'Excellent!';
        subtitle = 'The model predicts you will perform excellently';
        break;
      case 'good':
        icon = '😊';
        title = 'Good!';
        subtitle = 'The model predicts you will perform well';
        break;
      case 'pass':
        icon = '🎉';
        title = 'Passed Successfully!';
        subtitle = 'The model predicts you will pass';
        break;
      case 'fail':
      default:
        icon = '📚';
        title = 'At Risk';
        subtitle = 'The model predicts you may fail';
        break;
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: _gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context, 1.0),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 16),
                  ),
                ),
                const Spacer(),
                const Text(
                  'Your Result',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const Spacer(),
                const SizedBox(width: 38),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.4), width: 2),
                    ),
                    child:
                    Text(icon, style: const TextStyle(fontSize: 56)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8)),
                    textAlign: TextAlign.center,
                  ),

                  if (selfPrediction != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Your Expectation',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14),
                            ),
                            Text(
                              selfPrediction!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ]),
                    ),
                  ],

                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Prediction',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 14)),
                          Text(
                            result!['prediction']?.toString() ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF4F46E5),
                            ),
                          ),
                        ]),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding:
                            EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              'Recommendations for All Questions',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                          ),
                          ...questions.map((q) {
                            final apiRec = recommendations?.firstWhere(
                                  (rec) => rec['question'] == q.displayText,
                              orElse: () => null,
                            );
                            final yourAnswer = answers[q.id] ?? 'Not answered';
                            final recommendedAnswer = apiRec?['recommended_answer']?.toString() ?? 'No specific recommendation.';

                            return Column(
                              children: [
                                const Divider(
                                    height: 1,
                                    color: Color(0xFFEEEEEE)),
                                Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          q.displayText,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(children: [
                                          const Icon(Icons.close,
                                              color: Colors.red,
                                              size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Your answer: $yourAnswer',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.red),
                                          ),
                                        ]),
                                        const SizedBox(height: 4),
                                        Row(children: [
                                          const Icon(Icons.check,
                                              color: Colors.green,
                                              size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Recommended: $recommendedAnswer',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.green),
                                          ),
                                        ]),
                                      ]),
                                ),
                              ],
                            );
                          }).toList(),
                        ]),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () {
                      reset();
                      Navigator.pop(context, 0.0);
                    },
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.refresh_rounded,
                                color: Color(0xFF4F46E5)),
                            SizedBox(width: 8),
                            Text(
                              'Retake Quiz',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                          ]),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}