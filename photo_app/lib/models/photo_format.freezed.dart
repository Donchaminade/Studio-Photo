// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'photo_format.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PhotoFormat _$PhotoFormatFromJson(Map<String, dynamic> json) {
  return _PhotoFormat.fromJson(json);
}

/// @nodoc
mixin _$PhotoFormat {
  String get dimension => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  List<String> get images => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  bool get isPopular => throw _privateConstructorUsedError;
  double? get framePrice => throw _privateConstructorUsedError;

  /// Serializes this PhotoFormat to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PhotoFormat
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PhotoFormatCopyWith<PhotoFormat> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PhotoFormatCopyWith<$Res> {
  factory $PhotoFormatCopyWith(
          PhotoFormat value, $Res Function(PhotoFormat) then) =
      _$PhotoFormatCopyWithImpl<$Res, PhotoFormat>;
  @useResult
  $Res call(
      {String dimension,
      double price,
      List<String> images,
      String title,
      String description,
      bool isPopular,
      double? framePrice});
}

/// @nodoc
class _$PhotoFormatCopyWithImpl<$Res, $Val extends PhotoFormat>
    implements $PhotoFormatCopyWith<$Res> {
  _$PhotoFormatCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PhotoFormat
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dimension = null,
    Object? price = null,
    Object? images = null,
    Object? title = null,
    Object? description = null,
    Object? isPopular = null,
    Object? framePrice = freezed,
  }) {
    return _then(_value.copyWith(
      dimension: null == dimension
          ? _value.dimension
          : dimension // ignore: cast_nullable_to_non_nullable
              as String,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      images: null == images
          ? _value.images
          : images // ignore: cast_nullable_to_non_nullable
              as List<String>,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      isPopular: null == isPopular
          ? _value.isPopular
          : isPopular // ignore: cast_nullable_to_non_nullable
              as bool,
      framePrice: freezed == framePrice
          ? _value.framePrice
          : framePrice // ignore: cast_nullable_to_non_nullable
              as double?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PhotoFormatImplCopyWith<$Res>
    implements $PhotoFormatCopyWith<$Res> {
  factory _$$PhotoFormatImplCopyWith(
          _$PhotoFormatImpl value, $Res Function(_$PhotoFormatImpl) then) =
      __$$PhotoFormatImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String dimension,
      double price,
      List<String> images,
      String title,
      String description,
      bool isPopular,
      double? framePrice});
}

/// @nodoc
class __$$PhotoFormatImplCopyWithImpl<$Res>
    extends _$PhotoFormatCopyWithImpl<$Res, _$PhotoFormatImpl>
    implements _$$PhotoFormatImplCopyWith<$Res> {
  __$$PhotoFormatImplCopyWithImpl(
      _$PhotoFormatImpl _value, $Res Function(_$PhotoFormatImpl) _then)
      : super(_value, _then);

  /// Create a copy of PhotoFormat
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dimension = null,
    Object? price = null,
    Object? images = null,
    Object? title = null,
    Object? description = null,
    Object? isPopular = null,
    Object? framePrice = freezed,
  }) {
    return _then(_$PhotoFormatImpl(
      dimension: null == dimension
          ? _value.dimension
          : dimension // ignore: cast_nullable_to_non_nullable
              as String,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      images: null == images
          ? _value._images
          : images // ignore: cast_nullable_to_non_nullable
              as List<String>,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      isPopular: null == isPopular
          ? _value.isPopular
          : isPopular // ignore: cast_nullable_to_non_nullable
              as bool,
      framePrice: freezed == framePrice
          ? _value.framePrice
          : framePrice // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PhotoFormatImpl with DiagnosticableTreeMixin implements _PhotoFormat {
  const _$PhotoFormatImpl(
      {required this.dimension,
      required this.price,
      required final List<String> images,
      required this.title,
      required this.description,
      this.isPopular = false,
      this.framePrice})
      : _images = images;

  factory _$PhotoFormatImpl.fromJson(Map<String, dynamic> json) =>
      _$$PhotoFormatImplFromJson(json);

  @override
  final String dimension;
  @override
  final double price;
  final List<String> _images;
  @override
  List<String> get images {
    if (_images is EqualUnmodifiableListView) return _images;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_images);
  }

  @override
  final String title;
  @override
  final String description;
  @override
  @JsonKey()
  final bool isPopular;
  @override
  final double? framePrice;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'PhotoFormat(dimension: $dimension, price: $price, images: $images, title: $title, description: $description, isPopular: $isPopular, framePrice: $framePrice)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'PhotoFormat'))
      ..add(DiagnosticsProperty('dimension', dimension))
      ..add(DiagnosticsProperty('price', price))
      ..add(DiagnosticsProperty('images', images))
      ..add(DiagnosticsProperty('title', title))
      ..add(DiagnosticsProperty('description', description))
      ..add(DiagnosticsProperty('isPopular', isPopular))
      ..add(DiagnosticsProperty('framePrice', framePrice));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PhotoFormatImpl &&
            (identical(other.dimension, dimension) ||
                other.dimension == dimension) &&
            (identical(other.price, price) || other.price == price) &&
            const DeepCollectionEquality().equals(other._images, _images) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.isPopular, isPopular) ||
                other.isPopular == isPopular) &&
            (identical(other.framePrice, framePrice) ||
                other.framePrice == framePrice));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      dimension,
      price,
      const DeepCollectionEquality().hash(_images),
      title,
      description,
      isPopular,
      framePrice);

  /// Create a copy of PhotoFormat
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PhotoFormatImplCopyWith<_$PhotoFormatImpl> get copyWith =>
      __$$PhotoFormatImplCopyWithImpl<_$PhotoFormatImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PhotoFormatImplToJson(
      this,
    );
  }
}

abstract class _PhotoFormat implements PhotoFormat {
  const factory _PhotoFormat(
      {required final String dimension,
      required final double price,
      required final List<String> images,
      required final String title,
      required final String description,
      final bool isPopular,
      final double? framePrice}) = _$PhotoFormatImpl;

  factory _PhotoFormat.fromJson(Map<String, dynamic> json) =
      _$PhotoFormatImpl.fromJson;

  @override
  String get dimension;
  @override
  double get price;
  @override
  List<String> get images;
  @override
  String get title;
  @override
  String get description;
  @override
  bool get isPopular;
  @override
  double? get framePrice;

  /// Create a copy of PhotoFormat
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PhotoFormatImplCopyWith<_$PhotoFormatImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
