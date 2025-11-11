// lib\interactive_sankey_painter.dart

import 'package:flutter/material.dart';
import 'package:sankey_flutter/sankey_link.dart';
import 'package:sankey_flutter/sankey_node.dart';
import 'package:sankey_flutter/sankey_painter.dart';
import 'dart:ui' as ui;

/// A [SankeyPainter] subclass that adds interactivity:
///
/// - Supports custom node colors per label
/// - Highlights connected links when a node is selected
/// - Applies hover/focus feedback with opacity and borders
class InteractiveSankeyPainter extends SankeyPainter {
  /// Map of node labels to specific colors
  final Map<String, Color> nodeColors;

  /// ID of the currently selected node, if any
  final int? selectedNodeId;
  final Color? darkColor;
  final Color? lightColor;
  final FontWeight? fontWeight;
  final String? fontFamily;
  final double? fontSize;
  final bool? gradientLinks;

  InteractiveSankeyPainter({
    required List<SankeyNode> nodes,
    required List<SankeyLink> links,
    required this.nodeColors,
    this.selectedNodeId,
    bool showLabels = true,
    Color linkColor = Colors.grey,
    this.darkColor,
    this.lightColor,
    this.fontWeight = FontWeight.bold,
    this.fontFamily,
    this.fontSize,
    this.gradientLinks
  }) : super(
          showLabels: showLabels,
          nodes: nodes,
          links: links,
          nodeColor: Colors.blue, // fallback node color
          linkColor: linkColor,
        );

  /// Blends two colors for transition effects (used in link paths)
  Color blendColors(Color a, Color b) => Color.lerp(a, b, 0.5) ?? a;

  @override
  void paint(Canvas canvas, Size size) {
    // --- Draw enhanced links ---
    for (SankeyLink link in links) {
      final source = link.source as SankeyNode;
      final target = link.target as SankeyNode;

      final sourceColor = nodeColors[source.label] ?? Colors.blue;
      final targetColor = nodeColors[target.label] ?? Colors.blue;
      var blended = blendColors(sourceColor, targetColor);
      final xMid = (source.x1 + target.x0) / 2;
      final yMid = (source.y1 + target.y0) / 2;

      // Highlight links connected to the selected node
      final isConnected = (selectedNodeId != null) &&
          (source.id == selectedNodeId || target.id == selectedNodeId);
      blended = blended.withOpacity(isConnected ? 0.9 : 0.5);

      final linkPaint;
      
      if (gradientLinks??false){
        linkPaint = Paint()
          //..color = blended
          ..shader =  ui.Gradient.linear(
            Offset(source.x0, yMid),
            Offset(target.x0, yMid),
            [
              sourceColor.withAlpha(128),
              targetColor.withAlpha(128),
            ])
          ..style = PaintingStyle.stroke
          ..strokeWidth = link.width;
      }else{
        linkPaint = Paint()
          ..color = blended
          ..style = PaintingStyle.stroke
          ..strokeWidth = link.width;
      }

      final path = Path();
      
      path.moveTo(source.x1, link.y0);
      path.cubicTo(xMid, link.y0, xMid, link.y1, target.x0, link.y1);

      canvas.drawPath(path, linkPaint);
    }

    // --- Draw colored nodes and labels with selection borders ---
    for (SankeyNode node in nodes) {
      final color = nodeColors[node.label] ?? Colors.blue;
      final rect =
          Rect.fromLTWH(node.x0, node.y0, node.x1 - node.x0, node.y1 - node.y0);
      final isSelected = selectedNodeId != null && node.id == selectedNodeId;

      canvas.drawRect(rect, Paint()..color = color);

      if (isSelected) {
        final borderPaint = Paint()
          ..color = Colors.yellow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;
        canvas.drawRect(rect, borderPaint);
      }

      final isDark = color.computeLuminance() < 0.05;
      final textColor = isDark ? darkColor ?? Colors.white : lightColor ?? Colors.black;
      final textOutlineColor = !isDark ? darkColor ?? Colors.white : lightColor ?? Colors.black;

      if (node.label != null && showLabels) {
        final TextPainter textPainter = TextPainter(
          text: TextSpan(
          text: node.label,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize ?? 10,
            fontWeight: fontWeight,
            fontFamily: fontFamily,
            ),
        ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout(minWidth: 0, maxWidth: size.width);

        final TextPainter strokePainter = TextPainter(
          text: TextSpan(
          text: node.label,
          style: TextStyle(
            fontSize: fontSize ?? 10,
            fontWeight: fontWeight,
            fontFamily: fontFamily,
            foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = textOutlineColor
            ..strokeJoin = StrokeJoin.round,
            ),
        ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout(minWidth: 0, maxWidth: size.width);

        const margin = 6.0;
        final labelY = rect.top + (rect.height - textPainter.height) / 2;
        final labelOffsetRight = Offset(rect.right + margin, labelY);
        final labelOffsetLeft =
            Offset(rect.left - margin - textPainter.width, labelY);

        // Automatically choose a side that fits within the canvas
        final labelOffset =
            (rect.right + margin + textPainter.width <= size.width)
                ? labelOffsetRight
                : (rect.left - margin - textPainter.width >= 0)
                    ? labelOffsetLeft
                    : labelOffsetRight;

        
        strokePainter.paint(canvas, labelOffset);
        textPainter.paint(canvas, labelOffset);
        
      }
    }
  }
}
