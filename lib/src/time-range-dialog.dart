import 'dart:math';

import 'package:flutter/material.dart';
import 'package:time_range_picker/src/clock-painter.dart';
import 'package:time_range_picker/src/utils.dart';

showTimeRangePicker({
  BuildContext context,

  String cancelLbl = "Cancel",
  String okLbl = "Ok",

  /// preselected start time
  TimeOfDay start,

  /// preselected end time
  TimeOfDay end,

  /// disabled time range (this time cannot be selected)
  TimeRange disabledTime,

  /// the color for the disabled section
  Color disabledColor,

  /// Style of the arc (filled or stroke)
  PaintingStyle paintingStyle,

  /// if start time changed
  void Function(TimeOfDay) onStartChange,

  /// if end time changed
  void Function(TimeOfDay) onEndChange,

  /// Minimum time steps that can be selected
  Duration interval = const Duration(minutes: 5),

  /// label for start time
  String fromText = "From",

  /// label for end time
  String toText = "To",

  /// use 24 hours or am / pm
  bool use24HourFormat = true,

  /// the padding of the ring
  double padding,

  /// the thickness of the ring
  double strokeWidth = 12,

  /// the color of the active arc from start time to end time
  Color strokeColor,

  /// the radius of the handler to drag the arc
  double handlerRadius = 12,

  /// the color of a  handler
  Color handlerColor,

  /// the color of a selected handler
  Color selectedColor,

  /// the color of the circle outline
  Color backgroundColor,

  /// a widget displayed in the background, use e.g. an image
  Widget backgroundWidget,

  /// number of ticks displayed
  int ticks,

  /// the offset for ticks
  double ticksOffset,

  /// ticks length
  double ticksLength,

  /// ticks thickness
  double ticksWidth,

  /// Color of ticks
  Color ticksColor = Colors.white,

  /// Snap time bar to interval
  bool snap = false,

  /// Show labels around the circle (start at 0 hours)
  List<ClockLabel> labels,

  /// Offset of the labels
  double labelOffset,

  /// rotate labels
  bool rotateLabels,

  /// flip labels if the angle woulb be upside down (only if rotate labels is active)
  bool autoAdjustLabels,

  /// Style of the labels
  TextStyle labelStyle,

  /// TextStyle of the time texts
  TextStyle timeTextStyle,

  /// TextStyle of the currently moving time text
  TextStyle activeTimeTextStyle,

  String message="",
  /// hide the time texts
  bool hideTimes = false,
  TransitionBuilder builder,
  bool useRootNavigator = true,
  RouteSettings routeSettings,
}) async {
  assert(context != null);
  assert(useRootNavigator != null);
  assert(debugCheckHasMaterialLocalizations(context));

  final Widget dialog = _TimeRangePicker(
    start: start,
    end: end,
    disabledTime: disabledTime,
    paintingStyle: paintingStyle,
    onStartChange: onStartChange,
    onEndChange: onEndChange,
    fromText: fromText,
    toText: toText,
    interval: interval,
    padding: padding,
    strokeWidth: strokeWidth,
    handlerRadius: handlerRadius,
    strokeColor: strokeColor,
    handlerColor: handlerColor,
    selectedColor: selectedColor,
    backgroundColor: backgroundColor,
    disabledColor: disabledColor,
    backgroundWidget: backgroundWidget,
    ticks: ticks,
    ticksLength: ticksLength,
    ticksWidth: ticksWidth,
    ticksOffset: ticksOffset,
    ticksColor: ticksColor,
    snap: snap,
    labels: labels,
    labelOffset: labelOffset,
    rotateLabels: rotateLabels,
    autoAdjustLabels: autoAdjustLabels,
    labelStyle: labelStyle,
    timeTextStyle: timeTextStyle,
    activeTimeTextStyle: activeTimeTextStyle,
    hideTimes: hideTimes,
    message: message,
    cancelLbl : cancelLbl,
  );

  return await showDialog<TimeRange>(
    context: context,
    useRootNavigator: true,
    builder: (BuildContext context) {
      return builder == null ? dialog : builder(context, dialog);
    },
    routeSettings: routeSettings,
  );
}

class _TimeRangePicker extends StatefulWidget {
  final TimeOfDay start;
  final TimeOfDay end;

  final TimeRange disabledTime;

  final void Function(TimeOfDay) onStartChange;
  final void Function(TimeOfDay) onEndChange;

  final Duration interval;

  final String toText;
  final String fromText;

  final double padding;
  final double strokeWidth;
  final double handlerRadius;
  final Color strokeColor;

  final Color handlerColor;
  final Color selectedColor;
  final Color backgroundColor;
  final Color disabledColor;
  final PaintingStyle paintingStyle;

  final Widget backgroundWidget;
  final int ticks;

  final double ticksOffset;

  final double ticksLength;

  final double ticksWidth;

  final Color ticksColor;
  final bool snap;

  final List<ClockLabel> labels;
  final double labelOffset;
  final bool rotateLabels;
  final bool autoAdjustLabels;
  final TextStyle labelStyle;

  final TextStyle timeTextStyle;
  final TextStyle activeTimeTextStyle;

  final bool hideTimes;

  final String message;
  final String cancelLbl;
  final String okLbl;

  _TimeRangePicker({
    Key key,
    this.cancelLbl="Cancel",
    this.okLbl = "Ok",
    this.message="message",
    this.start,
    this.end,
    this.disabledTime,
    this.onStartChange,
    this.onEndChange,
    this.fromText = "From",
    this.toText = "To",
    this.interval = const Duration(minutes: 5),
    this.padding = 26,
    this.strokeWidth = 12,
    this.handlerRadius = 12,
    this.strokeColor,
    this.handlerColor,
    this.selectedColor,
    this.backgroundColor,
    this.disabledColor,
    this.paintingStyle,
    this.backgroundWidget,
    this.ticks = 12,
    this.ticksLength,
    this.ticksWidth,
    this.ticksOffset,
    this.ticksColor = Colors.white,
    this.snap = false,
    this.labels,
    this.labelOffset,
    this.rotateLabels,
    this.autoAdjustLabels,
    this.labelStyle,
    this.timeTextStyle,
    this.activeTimeTextStyle,
    this.hideTimes,
  }) : super(key: key);

  @override
  _TimeRangePickerState createState() => _TimeRangePickerState();
}

class _TimeRangePickerState extends State<_TimeRangePicker>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  ActiveTime _activeTime;
  double _startAngle = 0;
  double _endAngle = 0;
  //String message;    //adkjhcksahlchlkajclksjlkklnslkanzdknsaklcnklsncl
  double _disabledStartAngle;
  double _disabledEndAngle;

  final GlobalKey _circleKey = GlobalKey();
  final GlobalKey _wrapperKey = GlobalKey();

  TimeOfDay _startTime;
  TimeOfDay _endTime;
  double _radius = 50;
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    var startTime = widget.start ?? TimeOfDay.now();
    var endTime = widget.end ??
        startTime.replacing(
            hour:
            startTime.hour < 21 ? startTime.hour + 3 : startTime.hour - 21);

    _startTime = _roundMinutes(startTime.hour * 60 + startTime.minute * 1.0);
    _startAngle = timeToAngle(_startTime);
    _endTime = _roundMinutes(endTime.hour * 60 + endTime.minute * 1.0);
    _endAngle = timeToAngle(_endTime);

    if (widget.disabledTime != null) {
      _disabledStartAngle = timeToAngle(widget.disabledTime.startTime);
      _disabledEndAngle = timeToAngle(widget.disabledTime.endTime);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => setRadius());

    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) => setRadius());
  }

  setRadius() {
    RenderBox wrapper = _wrapperKey?.currentContext?.findRenderObject();
    if (wrapper != null) {
      setState(() {
        _radius = min(wrapper.size.width, wrapper.size.height) / 2 -
            (widget.padding ?? 26);
      });
    }
  }

  TimeOfDay _angleToTime(double angle) {
    angle = normalizeAngle(angle - pi / 2);
    double min = 24 * 60 * (angle) / (pi * 2);

    return _roundMinutes(min);
  }

  TimeOfDay _roundMinutes(double min) {
    int roundedMin =
    ((min / widget.interval.inMinutes).round() * widget.interval.inMinutes);

    int hours = (roundedMin / 60).floor();
    int minutes = (roundedMin % 60).round();
    return TimeOfDay(hour: hours, minute: minutes);
  }

  void _panStart(DragStartDetails details) {
    var globalPoint = details.globalPosition;
    var snap = widget.handlerRadius * 2.5;
    RenderBox circle = _circleKey.currentContext.findRenderObject();

    CustomPaint customPaint = _circleKey.currentWidget;
    ClockPainter _clockPainter = customPaint.painter;

    if (_clockPainter.startHandlerPosition == null) {
      setState(() {
        _activeTime = ActiveTime.Start;
      });
      return;
    }

    Offset globalStartOffset =
    circle.localToGlobal(_clockPainter.startHandlerPosition);
    if (globalPoint.dx < globalStartOffset.dx + snap &&
        globalPoint.dx > globalStartOffset.dx - snap &&
        globalPoint.dy < globalStartOffset.dy + snap &&
        globalPoint.dy > globalStartOffset.dy - snap) {
      setState(() {
        _activeTime = ActiveTime.Start;
      });
    }

    if (_clockPainter.endHandlerPosition == null) {
      setState(() {
        _activeTime = ActiveTime.End;
      });
      return;
    }

    Offset globalEndOffset =
    circle.localToGlobal(_clockPainter.endHandlerPosition);

    if (globalPoint.dx < globalEndOffset.dx + snap &&
        globalPoint.dx > globalEndOffset.dx - snap &&
        globalPoint.dy < globalEndOffset.dy + snap &&
        globalPoint.dy > globalEndOffset.dy - snap) {
      setState(() {
        _activeTime = ActiveTime.End;
      });
    }
  }

  void _panUpdate(DragUpdateDetails details) {
    if (_activeTime == null) return;
    RenderBox circle = _circleKey.currentContext.findRenderObject();
    final center = circle.size.center(Offset.zero);
    final point = circle.globalToLocal(details.globalPosition);
    final touchPositionFromCenter = point - center;
    var dir = normalizeAngle(touchPositionFromCenter.direction);

    //check disabled
    if (widget.disabledTime != null) {
      var disabledStanEnd =
      standardizeToOffsetAngle(_disabledEndAngle, _disabledStartAngle);
      var stanDir = standardizeToOffsetAngle(dir, _disabledStartAngle);

      if (_activeTime == ActiveTime.Start) {
        var stanEnd = standardizeToOffsetAngle(_endAngle, _disabledStartAngle);

        if (isBetweenAngle(0, disabledStanEnd, stanDir) ||
            stanDir > stanEnd && stanEnd != 0) {
          dir = _disabledEndAngle;
        }
      } else {
        var stanStart =
        standardizeToOffsetAngle(_startAngle, _disabledStartAngle);

        if (isBetweenAngle(0, disabledStanEnd, stanDir) ||
            stanDir < stanStart) {
          dir = _disabledStartAngle;
        }
      }
    }

    final time = _angleToTime(dir);

    // snap to interval
    final angle = widget.snap == true ? timeToAngle(time) : dir;

    setState(() {
      if (_activeTime == ActiveTime.Start)
        _startAngle = angle;
      else
        _endAngle = angle;
    });
    _updateTime(time);
  }

  bool isBetweenAngle(double min, double max, double targetAngle) {
    var normalisedMin = min >= 0 ? min : 2 * pi + min;
    var normalisedMax = max >= 0 ? max : 2 * pi + max;
    var normalisedTarget =
    targetAngle >= 0 ? targetAngle : 2 * pi + targetAngle;

    return normalisedMin <= normalisedTarget &&
        normalisedTarget <= normalisedMax;
  }

  void _panEnd(DragEndDetails details) {
    setState(() {
      _activeTime = null;
    });
  }

  _updateTime(TimeOfDay time) {
    setState(() {
      if (_activeTime == ActiveTime.Start) {
        _startTime = time;
        if (widget.onStartChange != null) {
          widget.onStartChange(_startTime);
        }
      } else {
        _endTime = time;
        if (widget.onEndChange != null) {
          widget.onEndChange(_endTime);
        }
      }
    });
  }

  _submit() {

    Navigator.of(context)
        .pop(TimeRange(startTime: _startTime, endTime: _endTime));
  }

  _cancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations localizations =
    MaterialLocalizations.of(context);
    final ThemeData themeData = Theme.of(context);

    return Dialog(
      elevation: 12,
      child: OrientationBuilder(
        builder: (_, orientation) => orientation == Orientation.portrait
            ? Column(
          key: _wrapperKey,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            if (!widget.hideTimes) _buildHeader(false),
            Stack(
              //fit: StackFit.loose,
                alignment: Alignment.center,
                children: [
                  if (widget.backgroundWidget != null)
                    widget.backgroundWidget,
                  _buildTimeRange(
                      localizations: localizations, themeData: themeData)
                ]),
            _buildButtonBar(localizations: localizations)
          ],
        )
            : Row(
          children: [
            if (!widget.hideTimes) _buildHeader(true),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      key: _wrapperKey,
                      width: double.infinity,
                      child:
                      Stack(alignment: Alignment.center, children: [
                        if (widget.backgroundWidget != null)
                          widget.backgroundWidget,
                        _buildTimeRange(
                            localizations: localizations,
                            themeData: themeData)
                      ]),
                    ),
                  ),
                  _buildButtonBar(localizations: localizations)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonBar({@required MaterialLocalizations localizations}) =>
      ButtonBar(
        children: <Widget>[
          FlatButton(
            child: Text(widget.cancelLbl),
            onPressed: _cancel,
          ),
          FlatButton(
            child: Text(widget.okLbl),
            onPressed: _submit,
          ),
        ],
      );

  Widget _buildTimeRange(
      {@required MaterialLocalizations localizations,
        @required ThemeData themeData}) =>
      GestureDetector(
        onPanStart: _panStart,
        onPanUpdate: _panUpdate,
        onPanEnd: _panEnd,
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            color: Colors.white.withOpacity(0),
            child: Center(
              child: CustomPaint(
                key: _circleKey,
                painter: ClockPainter(
                  activeTime: _activeTime,
                  startAngle: _startAngle,
                  endAngle: _endAngle,
                  disabledStartAngle: _disabledStartAngle,
                  disabledEndAngle: _disabledEndAngle,
                  radius: _radius,
                  strokeWidth: widget.strokeWidth ?? 12,
                  handlerRadius: widget.handlerRadius ?? 12,
                  strokeColor: widget.strokeColor ?? themeData.primaryColor,
                  handlerColor: widget.handlerColor ?? themeData.primaryColor,
                  selectedColor:
                  widget.selectedColor ?? themeData.primaryColorLight,
                  backgroundColor: widget.backgroundColor ?? Colors.grey[200],
                  disabledColor:
                  widget.disabledColor ?? Colors.red.withOpacity(0.5),
                  paintingStyle: widget.paintingStyle ?? PaintingStyle.stroke,
                  ticks: widget.ticks,
                  ticksColor: widget.ticksColor ?? Colors.white,
                  ticksLength: widget.ticksLength ?? widget.strokeWidth ?? 12,
                  ticksWidth: widget.ticksWidth ?? 1,
                  ticksOffset: widget.ticksOffset ?? 0,
                  labels: widget.labels,
                  labelStyle:
                  widget.labelStyle ?? themeData.textTheme.bodyText1,
                  labelOffset: widget.labelOffset ?? 20,
                  rotateLabels: widget.rotateLabels ?? true,
                  autoAdjustLabels: widget.autoAdjustLabels ?? true,
                ),
                size: Size.fromRadius(_radius),
              ),
            ),
          ),
        ),
      );

  Widget _buildHeader(bool landscape) {
    final ThemeData themeData = Theme.of(context);

    Color backgroundColor;
    switch (themeData.brightness) {
      case Brightness.light:
        backgroundColor = themeData.primaryColor;
        break;
      case Brightness.dark:
        backgroundColor = themeData.backgroundColor;
        break;
    }

    Color activeColor;
    Color inactiveColor;
    switch (themeData.primaryColorBrightness) {
      case Brightness.light:
        activeColor = Colors.black87;
        inactiveColor = Colors.black54;
        break;
      case Brightness.dark:
        activeColor = Colors.white;
        inactiveColor = Colors.white70;
        break;
    }

    return Container(
      color: Colors.black,
      padding: EdgeInsets.all(24),
      child: Flex(
        direction: landscape ? Axis.vertical : Axis.horizontal,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Column(
                    children: [
                      Text(widget.fromText, style: TextStyle(color: activeColor)),
                      Text(
                        _startTime != null ? _startTime.format(context) : "-",
                        style: _activeTime == ActiveTime.Start
                            ? widget.activeTimeTextStyle ??
                            TextStyle(
                                color: activeColor,
                                fontSize: 28,
                                fontWeight: FontWeight.bold)
                            : widget.timeTextStyle ??
                            TextStyle(
                                color: inactiveColor,
                                fontSize: 28,
                                fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(width: 20,),
                  Column(children: [
                    Text(widget.toText, style: TextStyle(color: activeColor)),
                    Text(
                      _endTime != null ? _endTime.format(context) : "-",
                      style: _activeTime == ActiveTime.End
                          ? widget.activeTimeTextStyle ??
                          TextStyle(
                              color: activeColor,
                              fontSize: 28,
                              fontWeight: FontWeight.bold)
                          : widget.timeTextStyle ??
                          TextStyle(
                              color: inactiveColor,
                              fontSize: 28,
                              fontWeight: FontWeight.bold),
                    ),

                  ]),
                ],
              ),

              Text(widget.message ?? "", style: TextStyle(color: Colors.redAccent)),
            ],

          ),



        ],
      ),
    );
  }
}
