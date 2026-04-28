import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../models/trace_models.dart';
import '../repositories/trace_repository.dart';
import '../services/progress_service.dart';
import '../services/voice_service.dart';
import '../widgets/tracing_canvas.dart';

class TracingScreen extends StatefulWidget {
  const TracingScreen({
    super.key,
    required this.targetId,
    this.displayWord,
    this.autoAdvanceOnSuccess = false,
    this.letterSet = LetterSet.uppercase,
  });

  final String targetId;
  final String? displayWord;
  final bool autoAdvanceOnSuccess;
  final LetterSet letterSet;

  @override
  State<TracingScreen> createState() => _TracingScreenState();
}

class _TracingScreenState extends State<TracingScreen> {
  final _repo = TraceRepository();
  final _progressService = ProgressService.instance;
  final _voiceService = VoiceService.instance;
  final _confettiController = ConfettiController(
    duration: const Duration(seconds: 2),
  );
  final List<List<Offset>> _userStrokes = [];

  TraceTarget? _target;
  ProgressData _progress = const ProgressData(completedTargets: {}, stars: 0);
  bool _isOnTrack = true;
  bool _completed = false;
  bool _warnedOffTrack = false;
  Uint8List? _maskBytes;
  Size? _maskSize;
  int _maskWidth = 0;
  int _maskHeight = 0;
  Set<int> _targetCells = <int>{};
  final Set<int> _coveredCells = <int>{};
  final List<Rect> _characterRects = <Rect>[];
  final List<Set<int>> _characterCellSets = <Set<int>>[];
  bool _isPreparingMask = false;
  int _nearHitCount = 0;
  int _totalHitCount = 0;
  static const int _gridStep = 6;

  String get _guideText => (widget.displayWord ?? _target?.label ?? '').trim();

  @override
  void initState() {
    super.initState();
    _loadTarget();
  }

  Future<void> _loadTarget() async {
    final map = await _repo.loadLetters(set: widget.letterSet);
    final fallbackId = widget.letterSet == LetterSet.uppercase ? 'A' : 'a';
    final target = map[widget.targetId] ?? map[fallbackId];
    final progress = await _progressService.load();
    if (!mounted) return;
    setState(() {
      _target = target;
      _progress = progress;
    });
    await _voiceService.speak(
      widget.displayWord != null
          ? 'Trace le mot ${widget.displayWord}.'
          : 'Trace la lettre ${target?.label ?? ''}.',
    );
  }

  @override
  void dispose() {
    _voiceService.stop();
    _confettiController.dispose();
    super.dispose();
  }

  void _handlePanStart(DragStartDetails details, Size drawingSize) {
    if (_target == null || _completed) return;
    final local = details.localPosition;
    if (local.dx < 0 ||
        local.dy < 0 ||
        local.dx > drawingSize.width ||
        local.dy > drawingSize.height) {
      return;
    }
    setState(() {
      _userStrokes.add([local]);
    });
  }

  void _handlePanUpdate(DragUpdateDetails details, Size drawingSize) {
    if (_target == null || _completed) return;

    final local = details.localPosition;
    if (local.dx < 0 ||
        local.dy < 0 ||
        local.dx > drawingSize.width ||
        local.dy > drawingSize.height) {
      return;
    }

    if (_maskBytes == null || _maskSize != drawingSize) {
      _prepareLetterMask(drawingSize);
    }
    final isNearPath = _isNearLetter(local);

    setState(() {
      _isOnTrack = isNearPath;
      if (_userStrokes.isEmpty) {
        _userStrokes.add([local]);
      } else {
        _userStrokes.last.add(local);
      }
      _markCoverage(local);
      _totalHitCount++;
      if (isNearPath) {
        _nearHitCount++;
      }
      if (isNearPath) {
        _warnedOffTrack = false;
      }
    });

    if (!isNearPath && !_warnedOffTrack) {
      _warnedOffTrack = true;
      _voiceService.speak('Reviens doucement sur les pointilles.');
    }
  }

  Future<void> _validateCompletion(Size drawingSize) async {
    if (_target == null || _completed) return;
    final totalPoints = _userStrokes.fold<int>(0, (sum, stroke) => sum + stroke.length);
    if (totalPoints < 25) return;

    final completionRate = _targetCells.isEmpty
        ? 0.0
        : _coveredCells.length / _targetCells.length;
    final precisionRate =
        _totalHitCount == 0 ? 0.0 : _nearHitCount / _totalHitCount;
    final eachLetterTraced = _hasTracedEveryLetter();
    if (completionRate >= 0.38 && precisionRate >= 0.55 && eachLetterTraced) {
      final previousBadges = _progressService.unlockedBadges(_progress);
      setState(() => _completed = true);
      _confettiController.play();
      final progress = await _progressService.completeTarget(_target!.id);
      final newBadges = _progressService.unlockedBadges(progress);
      final unlockedNow = newBadges.where(
        (badge) => !previousBadges.any((old) => old.id == badge.id),
      );
      if (!mounted) return;
      setState(() => _progress = progress);
      if (unlockedNow.isNotEmpty) {
        final badge = unlockedNow.first;
        await _voiceService.speak(
          'Bravo ! Nouveau badge ${badge.title}. Niveau ${progress.level}.',
        );
      } else {
        await _voiceService.speak(
          'Bravo ! Niveau ${progress.level}. Tu as ${progress.stars} etoiles.',
        );
      }
      if (widget.autoAdvanceOnSuccess && mounted) {
        await Future<void>.delayed(const Duration(milliseconds: 900));
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    }
  }

  Future<void> _prepareLetterMask(Size drawingSize) async {
    if (_target == null || _isPreparingMask) return;
    _isPreparingMask = true;
    _maskSize = drawingSize;
    _maskWidth = drawingSize.width.round().clamp(1, 4000);
    _maskHeight = drawingSize.height.round().clamp(1, 4000);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final textPainter = TextPainter(
      text: TextSpan(
        text: _guideText,
        style: TextStyle(
          color: Colors.white,
          fontSize: _guideText.length <= 1
              ? drawingSize.height * 0.56
              : drawingSize.height * 0.26,
          fontWeight: FontWeight.w600,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: drawingSize.width * 0.92);

    final offset = Offset(
      (drawingSize.width - textPainter.width) / 2,
      (drawingSize.height - textPainter.height) / 2,
    );
    _characterRects
      ..clear()
      ..addAll(_buildCharacterRects(textPainter, offset));
    textPainter.paint(canvas, offset);

    final picture = recorder.endRecording();
    final image = await picture.toImage(_maskWidth, _maskHeight);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (mounted && data != null) {
      _maskBytes = data.buffer.asUint8List();
      _targetCells = _buildTargetCells();
      _characterCellSets
        ..clear()
        ..addAll(_buildCharacterCellSets());
      _coveredCells.clear();
    }
    _isPreparingMask = false;
  }

  List<Rect> _buildCharacterRects(TextPainter painter, Offset offset) {
    final rects = <Rect>[];
    final text = _guideText;
    for (var i = 0; i < text.length; i++) {
      if (text[i].trim().isEmpty) continue;
      final boxes = painter.getBoxesForSelection(
        TextSelection(baseOffset: i, extentOffset: i + 1),
      );
      if (boxes.isEmpty) continue;
      var merged = boxes.first.toRect();
      for (final box in boxes.skip(1)) {
        merged = merged.expandToInclude(box.toRect());
      }
      rects.add(merged.shift(offset).inflate(6));
    }
    return rects;
  }

  Set<int> _buildTargetCells() {
    if (_maskBytes == null) return <int>{};
    final cells = <int>{};
    for (var y = 0; y < _maskHeight; y += _gridStep) {
      for (var x = 0; x < _maskWidth; x += _gridStep) {
        if (_alphaAt(x, y) > 20) {
          cells.add((x ~/ _gridStep) + (y ~/ _gridStep) * 1000);
        }
      }
    }
    return cells;
  }

  List<Set<int>> _buildCharacterCellSets() {
    final sets = <Set<int>>[];
    if (_maskBytes == null) return sets;
    for (final rect in _characterRects) {
      final letterCells = <int>{};
      final left = rect.left.round().clamp(0, _maskWidth - 1);
      final top = rect.top.round().clamp(0, _maskHeight - 1);
      final right = rect.right.round().clamp(0, _maskWidth - 1);
      final bottom = rect.bottom.round().clamp(0, _maskHeight - 1);
      for (var y = top; y <= bottom; y += _gridStep) {
        for (var x = left; x <= right; x += _gridStep) {
          if (_alphaAt(x, y) > 20) {
            letterCells.add((x ~/ _gridStep) + (y ~/ _gridStep) * 1000);
          }
        }
      }
      sets.add(letterCells);
    }
    return sets;
  }

  void _markCoverage(Offset point) {
    if (_maskBytes == null) return;
    final x = point.dx.round().clamp(0, _maskWidth - 1);
    final y = point.dy.round().clamp(0, _maskHeight - 1);
    if (_alphaAround(x, y, 10) > 20) {
      _coveredCells.add((x ~/ _gridStep) + (y ~/ _gridStep) * 1000);
    }
  }

  bool _hasTracedEveryLetter() {
    if (_characterCellSets.isEmpty) return true;
    for (final letterCells in _characterCellSets) {
      if (letterCells.isEmpty) continue;
      var covered = 0;
      for (final cell in letterCells) {
        if (_coveredCells.contains(cell)) covered++;
      }
      final ratio = covered / letterCells.length;
      if (ratio < 0.28) {
        return false;
      }
    }
    return true;
  }

  bool _isNearLetter(Offset point) {
    if (_maskBytes == null) return false;
    final x = point.dx.round().clamp(0, _maskWidth - 1);
    final y = point.dy.round().clamp(0, _maskHeight - 1);
    return _alphaAround(x, y, 10) > 20;
  }

  int _alphaAround(int x, int y, int radius) {
    var maxAlpha = 0;
    for (var dy = -radius; dy <= radius; dy += 2) {
      for (var dx = -radius; dx <= radius; dx += 2) {
        final px = (x + dx).clamp(0, _maskWidth - 1);
        final py = (y + dy).clamp(0, _maskHeight - 1);
        final alpha = _alphaAt(px, py);
        if (alpha > maxAlpha) maxAlpha = alpha;
      }
    }
    return maxAlpha;
  }

  int _alphaAt(int x, int y) {
    if (_maskBytes == null) return 0;
    final index = (y * _maskWidth + x) * 4 + 3;
    if (index < 0 || index >= _maskBytes!.length) return 0;
    return _maskBytes![index];
  }

  void _clearDrawing() {
    setState(() {
      _userStrokes.clear();
      _completed = false;
      _isOnTrack = true;
      _warnedOffTrack = false;
      _coveredCells.clear();
      _nearHitCount = 0;
      _totalHitCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final target = _target;
    if (target == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.displayWord ?? 'Trace ${target.label}'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                'Niv. ${_progress.level}   ⭐ ${_progress.stars}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    widget.displayWord ?? 'Suis la lettre ${target.label}',
                    style: TextStyle(
                      fontSize: max(24, constraints.maxWidth * 0.04),
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, drawBox) {
                        final drawingSize = Size(
                          drawBox.maxWidth - 16,
                          drawBox.maxHeight - 16,
                        );
                        if (_maskBytes == null || _maskSize != drawingSize) {
                          _prepareLetterMask(drawingSize);
                        }
                        return Stack(
                          children: [
                            GestureDetector(
                              onPanStart: (details) =>
                                  _handlePanStart(details, drawingSize),
                              onPanUpdate: (details) =>
                                  _handlePanUpdate(details, drawingSize),
                              onPanEnd: (_) {
                                _validateCompletion(drawingSize);
                              },
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFCE93D8),
                                    width: 3,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: TracingCanvas(
                                    guideLabel: _guideText,
                                    userStrokes: _userStrokes,
                                    isOnTrack: _isOnTrack,
                                    showIllustration: _completed,
                                    successMessage: widget.displayWord != null
                                        ? 'Bravo !'
                                        : '${target.label}  ➜  ${target.illustration}',
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.topCenter,
                              child: ConfettiWidget(
                                confettiController: _confettiController,
                                blastDirectionality:
                                    BlastDirectionality.explosive,
                                shouldLoop: false,
                                numberOfParticles: 25,
                                colors: const [
                                  Colors.red,
                                  Colors.orange,
                                  Colors.yellow,
                                  Colors.green,
                                  Colors.blue,
                                  Colors.purple,
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _clearDrawing,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Recommencer'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(58),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isOnTrack
                        ? 'Super ! Ton tracé suit bien le chemin.'
                        : 'Oups, tu t’éloignes un peu. Reviens sur les pointillés !',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _isOnTrack ? Colors.green : Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
