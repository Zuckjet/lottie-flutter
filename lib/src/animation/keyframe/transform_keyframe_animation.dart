import 'dart:math' hide Point, Rectangle;
import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';
import '../../lottie_property.dart';
import '../../model/animatable/animatable_transform.dart';
import '../../model/layer/base_layer.dart';
import '../../utils.dart';
import '../../value/keyframe.dart';
import '../../value/lottie_value_callback.dart';
import '../../value/scale_xy.dart';
import 'base_keyframe_animation.dart';
import 'double_keyframe_animation.dart';
import 'value_callback_keyframe_animation.dart';

class TransformKeyframeAnimation {
  TransformKeyframeAnimation(AnimatableTransform animatableTransform)
      : _skewMatrix1 =
            animatableTransform.skew == null ? null : Matrix4.identity(),
        _skewMatrix2 =
            animatableTransform.skew == null ? null : Matrix4.identity(),
        _skewMatrix3 =
            animatableTransform.skew == null ? null : Matrix4.identity(),
        _anchorPoint = animatableTransform.anchorPoint?.createAnimation(),
        _position = animatableTransform.position?.createAnimation(),
        _scale = animatableTransform.scale?.createAnimation(),
        _rotation = animatableTransform.rotation?.createAnimation(),
        _skew = animatableTransform.skew?.createAnimation(),
        _skewAngle = animatableTransform.skewAngle?.createAnimation(),
        _opacity = animatableTransform.opacity?.createAnimation(),
        _startOpacity = animatableTransform.startOpacity?.createAnimation(),
        _endOpacity = animatableTransform.endOpacity?.createAnimation();

  final _matrix = Matrix4.identity();
  final Matrix4 _skewMatrix1;
  final Matrix4 _skewMatrix2;
  final Matrix4 _skewMatrix3;

  BaseKeyframeAnimation<Offset, Offset> /*?*/ _anchorPoint;
  BaseKeyframeAnimation<dynamic, Offset> /*?*/ _position;
  BaseKeyframeAnimation<ScaleXY, ScaleXY> /*?*/ _scale;
  BaseKeyframeAnimation<double, double> /*?*/ _rotation;
  DoubleKeyframeAnimation /*?*/ _skew;
  DoubleKeyframeAnimation /*?*/ _skewAngle;

  BaseKeyframeAnimation<int, int> /*?*/ _opacity;
  BaseKeyframeAnimation<int, int> /*?*/ get opacity => _opacity;

  BaseKeyframeAnimation<dynamic, double> /*?*/ _startOpacity;
  BaseKeyframeAnimation<dynamic, double> /*?*/ get startOpacity =>
      _startOpacity;

  BaseKeyframeAnimation<dynamic, double> /*?*/ _endOpacity;
  BaseKeyframeAnimation<dynamic, double> /*?*/ get endOpacity => _endOpacity;

  void addAnimationsToLayer(BaseLayer layer) {
    layer.addAnimation(_opacity);
    layer.addAnimation(_startOpacity);
    layer.addAnimation(_endOpacity);

    layer.addAnimation(_anchorPoint);
    layer.addAnimation(_position);
    layer.addAnimation(_scale);
    layer.addAnimation(_rotation);
    layer.addAnimation(_skew);
    layer.addAnimation(_skewAngle);
  }

  void addListener(void Function() listener) {
    _opacity?.addUpdateListener(listener);
    _startOpacity?.addUpdateListener(listener);
    _endOpacity?.addUpdateListener(listener);
    _anchorPoint?.addUpdateListener(listener);
    _position?.addUpdateListener(listener);
    _scale?.addUpdateListener(listener);
    _rotation?.addUpdateListener(listener);
    _skew?.addUpdateListener(listener);
    _skewAngle?.addUpdateListener(listener);
  }

  void setProgress(double progress) {
    _opacity?.setProgress(progress);
    _startOpacity?.setProgress(progress);
    _endOpacity?.setProgress(progress);
    _anchorPoint?.setProgress(progress);
    _position?.setProgress(progress);
    _scale?.setProgress(progress);
    _rotation?.setProgress(progress);
    _skew?.setProgress(progress);
    _skewAngle?.setProgress(progress);
  }

  Matrix4 getMatrix() {
    _matrix.reset();

    if (_position != null) {
      final position = _position.value;
      if (position.dx != 0 || position.dy != 0) {
        _matrix.translate(position.dx, position.dy);
      }
    }

    if (_rotation != null) {
      final rotation = _rotation.value;
      if (rotation != 0) {
        _matrix.rotateZ(rotation * pi / 180.0);
      }
    }

    if (_skew != null) {
      final mCos =
          _skewAngle == null ? 0.0 : cos(radians(-_skewAngle.value + 90));
      final mSin =
          _skewAngle == null ? 1.0 : sin(radians(-_skewAngle.value + 90));
      final aTan = tan(radians(_skew.value));

      _skewMatrix1.setValues(
        mCos, mSin, 0, 0,
        -mSin, mCos, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1, //
      );

      _skewMatrix2.setValues(
        1, 0, 0, 0,
        aTan, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1, //
      );

      _skewMatrix3.setValues(
        mCos, -mSin, 0, 0,
        mSin, mCos, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1, //
      );

      _skewMatrix2.multiply(_skewMatrix1);
      _skewMatrix3.multiply(_skewMatrix2);
      _matrix.multiply(_skewMatrix3);
    }

    if (_scale != null) {
      final scale = _scale.value;
      if (scale.x != 1 || scale.y != 1) {
        _matrix.scale(scale.x, scale.y);
      }
    }

    if (_anchorPoint != null) {
      final anchorPoint = _anchorPoint.value;
      if (anchorPoint.dx != 0 || anchorPoint.dy != 0) {
        _matrix.translate(-anchorPoint.dx, -anchorPoint.dy);
      }
    }

    return _matrix;
  }

  /// TODO: see if we can use this for the main {@link #getMatrix()} method.
  Matrix4 getMatrixForRepeater(double amount) {
    final position = _position?.value;
    final scale = _scale?.value;
    final rotation = _rotation?.value;

    _matrix.setIdentity();

    if (position != null) {
      _matrix.translate(position.dx, position.dy);
    }

    if (scale != null) {
      _matrix.scale(scale.x, scale.y);
    }

    if (rotation != null) {
      final anchorPoint = _anchorPoint?.value ?? Offset.zero;
      _matrix.translate(anchorPoint.dx, anchorPoint.dy);
      _matrix.rotateZ(rotation * pi / 180.0);
      _matrix.translate(-anchorPoint.dx, -anchorPoint.dy);
    }

    return _matrix;
  }

  bool applyValueCallback<T>(T property, LottieValueCallback<T> callback) {
    if (property == LottieProperty.TRANSFORM_ANCHOR_POINT) {
      if (_anchorPoint == null) {
        _anchorPoint = ValueCallbackKeyframeAnimation(
            callback as LottieValueCallback<Offset>, Offset.zero);
      } else {
        _anchorPoint.setValueCallback(callback as LottieValueCallback<Offset>);
      }
    } else if (property == LottieProperty.TRANSFORM_POSITION) {
      if (_position == null) {
        _position = ValueCallbackKeyframeAnimation(
            callback as LottieValueCallback<Offset>, Offset.zero);
      } else {
        _position.setValueCallback(callback as LottieValueCallback<Offset>);
      }
    } else if (property == LottieProperty.TRANSFORM_SCALE) {
      if (_scale == null) {
        _scale = ValueCallbackKeyframeAnimation(
            callback as LottieValueCallback<ScaleXY>, ScaleXY.one());
      } else {
        _scale.setValueCallback(callback as LottieValueCallback<ScaleXY>);
      }
    } else if (property == LottieProperty.TRANSFORM_ROTATION) {
      if (_rotation == null) {
        _rotation = ValueCallbackKeyframeAnimation(
            callback as LottieValueCallback<double>, 0.0);
      } else {
        _rotation.setValueCallback(callback as LottieValueCallback<double>);
      }
    } else if (property == LottieProperty.TRANSFORM_OPACITY) {
      if (_opacity == null) {
        _opacity = ValueCallbackKeyframeAnimation(
            callback as LottieValueCallback<int>, 100);
      } else {
        _opacity.setValueCallback(callback as LottieValueCallback<int>);
      }
    } else if (property == LottieProperty.TRANSFORM_START_OPACITY) {
      if (_startOpacity == null) {
        _startOpacity = ValueCallbackKeyframeAnimation(
            callback as LottieValueCallback<double>, 100);
      } else {
        _startOpacity.setValueCallback(callback as LottieValueCallback<double>);
      }
    } else if (property == LottieProperty.TRANSFORM_END_OPACITY) {
      if (_endOpacity == null) {
        _endOpacity = ValueCallbackKeyframeAnimation(
            callback as LottieValueCallback<double>, 100);
      } else {
        _endOpacity.setValueCallback(callback as LottieValueCallback<double>);
      }
    } else if (property == LottieProperty.TRANSFORM_SKEW) {
      _skew ??= DoubleKeyframeAnimation([Keyframe.nonAnimated(0.0)]);
      _skew.setValueCallback(callback as LottieValueCallback<double>);
    } else if (property == LottieProperty.TRANSFORM_SKEW_ANGLE) {
      _skewAngle ??= DoubleKeyframeAnimation([Keyframe.nonAnimated(0.0)]);
      _skewAngle.setValueCallback(callback as LottieValueCallback<double>);
    } else {
      return false;
    }

    return true;
  }
}
